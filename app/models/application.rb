class Application < ApplicationRecord
    has_many :chats, foreign_key: :token
    validates :name, :presence => true, :length => { :minimum => 5, :maximum => 20}
    before_create :generate_token

    protected

    def generate_token
        self.token = SecureRandom.uuid
    end
end
