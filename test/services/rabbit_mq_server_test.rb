require "test_helper"

class RabbitMqServerTest < ActiveSupport::TestCase
  test 'shoud create 5 different chats' do
    begin
      server = RabbitMqServer.new
      concurrency_level = 5
      chats = []
      threads = concurrency_level.times.map do |i|
        Thread.new do
          chat = server.forward_action(JSON.parse({ action: 'chat.create', params: 'abcdef' }.to_json))
          chats << chat[:data]
        end
      end
      threads.each(&:join)
      assert chats.count == 5, "Should return 5 chats, returned #{chats.count} chats"
      assert chats[0].number != chats[1].number, "chat 0 number should not equal chat 1 number: #{chats[0].number}"
      assert chats[0].number != chats[2].number, "chat 0 number should not equal chat 2 number: #{chats[0].number}"
      assert chats[0].number != chats[3].number, "chat 0 number should not equal chat 3 number: #{chats[0].number}"
      assert chats[0].number != chats[4].number, "chat 0 number should not equal chat 4 number: #{chats[0].number}"
      assert chats[1].number != chats[0].number, "chat 1 number should not equal chat 0 number: #{chats[1].number}"
      assert chats[1].number != chats[2].number, "chat 1 number should not equal chat 2 number: #{chats[1].number}"
      assert chats[1].number != chats[3].number, "chat 1 number should not equal chat 3 number: #{chats[1].number}"
      assert chats[1].number != chats[4].number, "chat 1 number should not equal chat 4 number: #{chats[1].number}"
      assert chats[2].number != chats[1].number, "chat 2 number should not equal chat 1 number: #{chats[2].number}"
      assert chats[2].number != chats[0].number, "chat 2 number should not equal chat 0 number: #{chats[2].number}"
      assert chats[2].number != chats[3].number, "chat 2 number should not equal chat 3 number: #{chats[2].number}"
      assert chats[2].number != chats[4].number, "chat 2 number should not equal chat 4 number: #{chats[2].number}"
      assert chats[3].number != chats[1].number, "chat 3 number should not equal chat 1 number: #{chats[3].number}"
      assert chats[3].number != chats[2].number, "chat 3 number should not equal chat 2 number: #{chats[3].number}"
      assert chats[3].number != chats[0].number, "chat 3 number should not equal chat 0 number: #{chats[3].number}"
      assert chats[3].number != chats[4].number, "chat 3 number should not equal chat 4 number: #{chats[3].number}"
      assert chats[4].number != chats[1].number, "chat 4 number should not equal chat 1 number: #{chats[4].number}"
      assert chats[4].number != chats[2].number, "chat 4 number should not equal chat 2 number: #{chats[4].number}"
      assert chats[4].number != chats[3].number, "chat 4 number should not equal chat 3 number: #{chats[4].number}"
      assert chats[4].number != chats[0].number, "chat 4 number should not equal chat 0 number: #{chats[4].number}"
    ensure
      ActiveRecord::Base.connection_pool.disconnect!
    end
  end

  test 'shoud create 5 different messages' do
    begin
      server = RabbitMqServer.new
      concurrency_level = 5
      messages = []
      threads = concurrency_level.times.map do |i|
        Thread.new do
          message = server.forward_action(JSON.parse({ action: 'message.create', params: { application_token: 'abcdef', chat_number: 1, body: 'hi' } }.to_json))
          messages << message[:data]
        end
      end
      threads.each(&:join)
      assert messages.count == 5, "Should return 5 messages, returned #{messages.count} messages"
      assert messages[0].number != messages[1].number, "message 0 number should not equal message 1 number: #{messages[0].number}"
      assert messages[0].number != messages[2].number, "message 0 number should not equal message 2 number: #{messages[0].number}"
      assert messages[0].number != messages[3].number, "message 0 number should not equal message 3 number: #{messages[0].number}"
      assert messages[0].number != messages[4].number, "message 0 number should not equal message 4 number: #{messages[0].number}"
      assert messages[1].number != messages[0].number, "message 1 number should not equal message 0 number: #{messages[0].number}"
      assert messages[1].number != messages[2].number, "message 1 number should not equal message 2 number: #{messages[0].number}"
      assert messages[1].number != messages[3].number, "message 1 number should not equal message 3 number: #{messages[0].number}"
      assert messages[1].number != messages[4].number, "message 1 number should not equal message 4 number: #{messages[0].number}"
      assert messages[2].number != messages[1].number, "message 2 number should not equal message 1 number: #{messages[0].number}"
      assert messages[2].number != messages[0].number, "message 2 number should not equal message 0 number: #{messages[0].number}"
      assert messages[2].number != messages[3].number, "message 2 number should not equal message 3 number: #{messages[0].number}"
      assert messages[2].number != messages[4].number, "message 2 number should not equal message 4 number: #{messages[0].number}"
      assert messages[3].number != messages[1].number, "message 3 number should not equal message 1 number: #{messages[0].number}"
      assert messages[3].number != messages[2].number, "message 3 number should not equal message 2 number: #{messages[0].number}"
      assert messages[3].number != messages[0].number, "message 3 number should not equal message 0 number: #{messages[0].number}"
      assert messages[3].number != messages[4].number, "message 3 number should not equal message 4 number: #{messages[0].number}"
      assert messages[4].number != messages[1].number, "message 4 number should not equal message 1 number: #{messages[0].number}"
      assert messages[4].number != messages[2].number, "message 4 number should not equal message 2 number: #{messages[0].number}"
      assert messages[4].number != messages[3].number, "message 4 number should not equal message 3 number: #{messages[0].number}"
      assert messages[4].number != messages[0].number, "message 4 number should not equal message 0 number: #{messages[0].number}"
    ensure
      ActiveRecord::Base.connection_pool.disconnect!
    end
  end
end