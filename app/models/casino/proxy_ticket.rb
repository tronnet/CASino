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

  def self.cleanup_unconsumed
    self.where({
        created_at: CASino.config.proxy_ticket[:lifetime_unconsumed].seconds.ago,
        consumed: false
      }).destroy_all
  end

  def self.cleanup_consumed
    self.where({
        created_at: CASino.config.proxy_ticket[:lifetime_consumed].seconds.ago,
        consumed: true
      }).destroy_all
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
