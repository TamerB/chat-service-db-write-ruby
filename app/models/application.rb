class Application < ApplicationRecord
    validates :name, :presence => true, :length => { :minimum => 5, :maximum => 20}
    before_create :generate_token

    protected

    def generate_token
        self.token = SecureRandom.uuid
    end
end
