class RabbitMqServer < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: -> {return {data: 'not found', status: 404}}
    def initialize
        @connection = Bunny.new
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
                application = Application.new(value['params'])
                if application.save
                    return {data: application, status: 201}
                else
                    return {data: 'name is required', status: 400}
                end
            when 'application.update'
                application = Application.find(value['params']['token'])
                if application.update(value['params']['application'])
                    return {data: application, status: 200}
                else
                    return {data: 'unprocessed entity', status: 422}
                end
            when 'chat.create'
                application = Application.find(value['params'])
                chat = Chat.new(token: application.token)
                if chat.save
                    return {data: chat, status: 201}
                else
                    return {data: 'token is required', status: 400}
                end
            when 'message.create'
                chat = Chat.where(token: value['params']['application_token'], number: value['params']['chat_number']).first
                if chat.nil?
                    return {data: "not found", status: 404}
                else
                    message = Message.new(token: chat.token, chat_number: chat.number, body: value['params']['body'])
                    if message.save
                        return {data: message, status: 201}
                    else
                        return {data: 'one or more required field is missing', status: 400}
                    end
                end
            when 'message.update'
                message = Message.where(token: value['params']['application_token'], chat_number: value['params']['chat_number'], number: value['params']['number']).first
                if message.update(value['params']['message'])
                    return {data: message, status: 200}
                else
                    return {data: 'unprocessed entity', status: 422}
                end
            else
                return {data: 'unrecognized operation', status: 400}
            end
        rescue Exception
            return {data: 'something went wrong', status: 500}
        end
    end
end