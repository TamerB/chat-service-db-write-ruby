class Chat < ApplicationRecord
  self.primary_keys = :token, :number
  before_create :increment_number
  belongs_to :application, foreign_key: :token
  has_many :messages, :foreign_key => [:token, :chat_number]

  protected

  def increment_number
    last_chat = Chat.where(token: self.token).order('created_at').last

    if !last_chat.nil?
      self.number = last_chat.number + 1
    end
  end
end
