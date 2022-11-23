class Message < ApplicationRecord
  self.primary_keys = :token, :chat_number, :number
  belongs_to :chat, :foreign_key => [:token, :chat_number]
  before_create :increment_number
  validates :body, :presence => true

  protected

  def increment_number
    last_message = Message.where(token: self.token, chat_number: self.chat_number).order('created_at').last

    if !last_message.nil?
      self.number = last_message.number + 1
    end
  end
end
