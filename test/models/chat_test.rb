require "test_helper"

class ChatTest < ActiveSupport::TestCase
  test "should not save chat without token" do
    chat = Chat.new
    assert_not chat.save, "Should not save chat without a token"
  end

  test "should save chat with token" do
    chat = Chat.new(token: 'abcdef')
    assert chat.save, "Should save chat with a token"
  end
end
