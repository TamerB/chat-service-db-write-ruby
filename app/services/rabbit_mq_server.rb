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

    def forward_action(value)
        begin
            case value['action']
            when 'application.create'
                logger.info "Application create started: #{value['params']}"
                application = Application.new(name: value['params']['name'])
                if application.save
                    logger.info "Application show completed: #{value['params']}"
                    return {data: application, status: 201}
                else
                    logger.warn "Application show cancelled (name is required): #{value['params']}"
                    return {data: 'name is required', status: 400}
                end
            when 'application.update'
                logger.info "Application update started: #{value['params']}"
                application = Application.find(value['params']['token'])
                if application.update(value['params']['application'])
                    logger.info "Application update completed: #{value['params']}"
                    return {data: application, status: 200}
                else
                    logger.warn "Application update cancelled (unprocessed entity): #{value['params']}"
                    return {data: 'unprocessed entity', status: 422}
                end
            when 'chat.create'
                logger.info "Chat create started: #{value['params']}"
                application = Application.where(token: value['params']).first
                if application.nil?
                    logger.warn "Chat create cancelled (application not found): #{value['params']}"
                    return {data: 'application not found', status: 404}
                end
                chat = Chat.new(token: application.token)
                if chat.save
                    logger.info "Chat create completed: #{value['params']}"
                    return {data: chat, status: 201}
                else
                    logger.warn "Chat create cancelled (token is required): #{value['params']}"
                    return {data: 'token is required', status: 400}
                end
            when 'message.create'
                logger.info "Message create started: #{value['params']}"
                chat = Chat.where(token: value['params']['application_token'], number: value['params']['chat_number']).first
                if chat.nil?
                    logger.warn "Message create cancelled (chat not found): #{value['params']}"
                    return {data: "chat not found", status: 404}
                end
                message = Message.new(token: chat.token, chat_number: chat.number, body: value['params']['body'])
                if message.save
                    logger.info "Message create completed: #{value['params']}"
                    return {data: message, status: 201}
                else
                    logger.warn "Message create cancelled (required data missing): #{value['params']}"
                    return {data: 'one or more required field is missing', status: 400}
                end
            when 'message.update'
                logger.info "Message update started: #{value['params']}"
                message = Message.where(token: value['params']['application_token'], chat_number: value['params']['chat_number'], number: value['params']['number']).first
                if message.nil?
                    logger.warn "Message update cancelled (message not found): #{value['params']}"
                    return {data: "message not found", status: 404}
                end
                if message.update(value['params']['message'])
                    logger.info "Message update completed: #{value['params']}"
                    return {data: message, status: 200}
                else
                    logger.warn "Message update cancelled (unprocessed entity): #{value['params']}"
                    return {data: 'unprocessed entity', status: 422}
                end
            else
                logger.error "Bad request: Unrecognized operation"
                return {data: 'unrecognized operation', status: 400}
            end
        rescue Exception => e
            logger.error e.message
            return {data: 'something went wrong', status: 500}
        end
    end
end