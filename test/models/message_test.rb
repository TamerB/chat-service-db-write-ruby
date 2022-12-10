require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "should not save message without token" do
    message = Message.new
    assert_not message.save, "Should not save message without a token"
  end

  test "should not save message without chat number" do
    message = Message.new(token: 'abcdef')
    assert_not message.save, "Should not save message without a chat number"
  end

  test "should save chat with token and chat number" do
    message = Message.new(token: 'abcdef', chat_number: 1, body: 'testing')
    assert message.save, "Should save message with a token and chat number"
  end

  test "should update chat with token, chat number, number, and body" do
    message = Message.where(token: 'abcdef', chat_number: 1, number: 1).first
    assert message.update(body: 'testing'), "Should save message with a token, chat number, number, and body"
  end
end
