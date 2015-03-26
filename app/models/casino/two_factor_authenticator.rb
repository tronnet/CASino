
class CASino::TwoFactorAuthenticator
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "two_factor_authenticators"

  field :secret, type: String
  field :active, type: Boolean, :default => false

  belongs_to :user

  def self.cleanup
  	self.where({
  			created_at: self.lifetime.ago,
  			active: false
  		}).destroy_all
  end

  def self.lifetime
    CASino.config.two_factor_authenticator[:lifetime_inactive].seconds
  end

  def expired?
    !self.active? && (Time.now - (self.created_at || Time.now)) > self.class.lifetime
  end
end
