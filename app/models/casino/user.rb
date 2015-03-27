require 'casino/ticket_granting_ticket'

class CASino::User
	include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "users"

  field :authenticator, type: String
  field :username, type: String
  field :extra_attributes, type: Hash

  #serialize :extra_attributes, Hash

  has_many :ticket_granting_tickets, :class_name => "CASino::TicketGrantingTicket"
  has_many :two_factor_authenticators, :class_name => "CASino::TwoFactorAuthenticator"

  def active_two_factor_authenticator
    self.two_factor_authenticators.where(active: true).first
  end
end
