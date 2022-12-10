require 'time'

class RabbitMqServer < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: -> {return {data: 'not found', status: 404}}
  def initialize
    @connection = Bunny.new(host: ENV.fetch('MQ_HOST'), automatically_recover: false)
    @connection.start
    @channel = @connection.create_channel
  end
  
  def start(queue_name)
    @channel = $channel
    @connection = $connection
    @queue = channel.queue(queue_name)
    @exchange = channel.default_exchange
    subscribe_to_queue
  end
  
  def stop
    channel.close
    connection.close
  end
  
  def loop_forever
    # This loop only exists to keep the main thread
    # alive. Many real world apps won't need this.
    loop { sleep 5 }
  end

  def forward_action(value)
    case value['action']
    when 'application.create'
      return create_application(value['params'])
    when 'application.update'
      return update_application(value['params'])
    when 'chat.create'
      return create_chat(value['params'])
    when 'message.create'
      return create_message(value['params'])
    when 'message.update'
      return update_message(value['params'])
    else
      logger.error "Bad request (#{value['action']}): Unrecognized operation"
      return {data: 'Something went wrong. Please try again later', status: 500}
    end
  end
  
  private
  
  attr_reader :channel, :exchange, :queue, :connection
  
  def subscribe_to_queue
    queue.subscribe do |_delivery_info, properties, payload|
      result = forward_action(JSON.parse(payload))
      exchange.publish(
        result.to_json,
        routing_key: properties.reply_to,
        correlation_id: properties.correlation_id
      )
    end
  end

  def create_application(value)
    begin
      logger.info "Application create started: #{value}"
      application = Application.new(name: value['name'])
      if application.save
        logger.info "Application show completed: #{value}"
        return {data: application, status: 201}
      else
        logger.warn "Application show cancelled (name is required): #{value}"
        return {data: 'unprocessed entity', status: 400}
      end
    rescue Exception => e
      return catch_error('application create', e.message)
    end
  end

  def update_application(value)
    begin
      logger.info "Application update started: #{value}"
      application = Application.find(value['token'])
      if application.update(value['application'])
        logger.info "Application update completed: #{value}"
        return {data: application, status: 200}
      else
        logger.warn "Application update cancelled (unprocessed entity): #{value}"
        return {data: 'unprocessed entity', status: 422}
      end
    rescue Exception => e
      return catch_error('application update', e.message)
    end
  end

  def create_chat(value)
    begin
      logger.info "Chat create started: #{value}"
      application = Application.where(token: value).first
      if application.nil?
        logger.warn "Chat create cancelled (application not found): #{value}"
        return {data: 'application not found', status: 404}
      end
      
      chat = Chat.new(token: application.token)
      before = Time.now()
      loop do
        begin
          if chat.save
            logger.info "Chat create completed: #{value}"
            return {data: chat, status: 201}
          end
        rescue Exception => e
          if Time.now() - before > 1000.0
            logger.warn "Chat create cancelled #{e.message}: #{value}"
            return {data: 'unprocessed entity', status: 400}
          end
        end
      end
    rescue Exception => e
      return catch_error('Chat create', e.message)
    end
  end

  def create_message(value)
    begin
      logger.info "Message create started: #{value}"
      chat = Chat.where(token: value['application_token'], number: value['chat_number']).first
      if chat.nil?
        logger.warn "Message create cancelled (chat not found): #{value}"
        return {data: "chat not found", status: 404}
      end
      message = Message.new(token: chat.token, chat_number: chat.number, body: value['body'])
      
      before = Time.now()
      loop do
        begin
          if message.save
            logger.info "Message create completed: #{value}"
            return {data: message, status: 201}
          end
        rescue Exception => e
          if Time.now() - before > 1000.0
            logger.warn "Message create cancelled (#{e.message}): #{value}"
            return {data: 'Something went wrong. Please try again later', status: 500}
          end
        end
      end
    rescue Exception => e
      return catch_error('Message create', e.message)
    end
  end

  def update_message(value)
    begin
      logger.info "Message update started: #{value}"
      message = Message.where(token: value['application_token'], chat_number: value['chat_number'], number: value['number']).first
      if message.nil?
        logger.warn "Message update cancelled (message not found): #{value}"
        return {data: "message not found", status: 404}
      end
      if message.update(value['message'])
        logger.info "Message update completed: #{value}"
        return {data: message, status: 200}
      else
        logger.warn "Message update cancelled (unprocessed entity): #{value}"
        return {data: 'unprocessed entity', status: 422}
      end
    rescue Exception => e
      return catch_error('Message update', e.message)
    end
  end

  def catch_error(prefix, err)
    logger.error "#{prefix} cancelled: #{err}"
    return {data: 'something went wrong. Please try again later', status: 500}
  end
end