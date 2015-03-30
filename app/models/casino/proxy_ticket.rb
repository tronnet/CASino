require 'addressable/uri'

class CASino::ProxyTicket
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "proxy_tickets"

  field :ticket, type: String
  field :service, type: String
  field :consumed, type: Boolean, :default => false

  belongs_to :proxy_granting_ticket, :class_name => "CASino::ProxyGrantingTicket", inverse_of: :proxy_tickets
  has_and_belongs_to_many :proxy_granting_tickets, :class_name => "CASino::ProxyGrantingTicket", inverse_of: :granter, dependent: :destroy

  validates :ticket, uniqueness: true

  def self.find_by_ticket(ticket)
    self.where(ticket: ticket).first
  end

  def self.cleanup_unconsumed
    self.destroy_all({
        :created_at.lt => CASino.config.proxy_ticket[:lifetime_unconsumed].seconds.ago,
        :consumed => false
      })
  end

  def self.cleanup_consumed
    self.destroy_all({
        :created_at.lt => CASino.config.proxy_ticket[:lifetime_consumed].seconds.ago,
        :consumed => true
      })
  end

  def compact
    self.proxy_granting_tickets.compact
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
