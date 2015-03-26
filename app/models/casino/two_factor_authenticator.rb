
class CASino::TwoFactorAuthenticator
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "two_factor_authenticators"

  field :secret, type: String
  field :active, type: Boolean, :default => false

  belongs_to :user

  def self.cleanup
    self.delete_all(['(created_at < ?) AND active = ?', self.lifetime.ago, false])
  end

  def self.lifetime
    CASino.config.two_factor_authenticator[:lifetime_inactive].seconds
  end

  def expired?
    !self.active? && (Time.now - (self.created_at || Time.now)) > self.class.lifetime
  end
end
