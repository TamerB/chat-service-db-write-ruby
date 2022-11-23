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
            puts "22222222222222222"
            puts value
            application = Application.find(value['params'])
            puts "11111111111"
            puts application
            puts application.token
            chat = Chat.new(token: application.token)
            if chat.save
                return {data: chat, status: 201}
            else
                return {data: 'token is required', status: 400}
            end
        when 'message.create'
            @application = Application.new(value[:params])
            if @application.save
                return {data: @application, status: 201}
            else
                return {data: 'name is required', status: 400}
            end
        when 'message.update'
            @application = Application.new(value[:params])
            if @application.save
                return {data: @application, status: 201}
            else
                return {data: 'name is required', status: 400}
            end
        else
            return {data: 'unrecognized operation', status: 400}
        end
    end
end