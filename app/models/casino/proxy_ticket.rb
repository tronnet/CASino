require 'addressable/uri'

class CASino::ProxyTicket
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "proxy_tickets"

  field :ticket, type: String
  field :service, type: String
  field :consumed, type: Boolean, :default => false

  validates :ticket, uniqueness: true
  belongs_to :proxy_granting_ticket
  has_many :proxy_granting_tickets, as: :granter, dependent: :destroy

  def self.cleanup_unconsumed
    self.destroy_all(['created_at < ? AND consumed = ?', CASino.config.proxy_ticket[:lifetime_unconsumed].seconds.ago, false])
  end

  def self.cleanup_consumed
    self.destroy_all(['created_at < ? AND consumed = ?', CASino.config.proxy_ticket[:lifetime_consumed].seconds.ago, true])
  end

  def expired?
    lifetime = if consumed?
      CASino.config.proxy_ticket[:lifetime_consumed]
    else
      CASino.config.proxy_ticket[:lifetime_unconsumed]
    end
    (Time.now - (self.created_at || Time.now)) > lifetime
  end
end
