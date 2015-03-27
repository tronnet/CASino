require 'addressable/uri'

class CASino::ServiceTicket
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "service_tickets"

  field :ticket, type: String
  field :service, type: String
  field :consumed, type: Boolean, :default => false
  field :issued_from_credentials, type: Boolean, :default => false

  validates :ticket, uniqueness: true
  belongs_to :ticket_granting_ticket, :class_name => "CASino::TicketGrantingTicket"
  before_destroy :send_single_sign_out_notification, if: :consumed?
  has_many :proxy_granting_tickets, :class_name => "CASino::ProxyGrantingTicket", as: :granter, dependent: :destroy

  def self.cleanup_unconsumed
  	self.where({
  			:created_at.lt => CASino.config.service_ticket[:lifetime_unconsumed].seconds.ago,
  			:consumed => false
  		}).destroy_all
  end

  def self.cleanup_consumed
  	self.where({
  			:created_at.lt => CASino.config.service_ticket[:lifetime_consumed].seconds.ago,
  			:consumed => true
  		}).destroy_all

  	self.where({
  			:ticket_granting_ticket_id.exists => false
  		}).destroy_all
  end

  def self.cleanup_consumed_hard
  	self.where({
  			:created_at.lt => (CASino.config.service_ticket[:lifetime_consumed] * 2).seconds.ago,
  			:consumed => true
  		}).destroy_all
  end

  def self.find_by_ticket(ticket)
  	self.where(ticket: ticket).first
  end

  def service=(service)
    normalized_encoded_service = Addressable::URI.parse(service).normalize.to_str
    super(normalized_encoded_service)
  end


  def service_with_ticket_url
    service_uri = Addressable::URI.parse(self.service)
    service_uri.query_values = (service_uri.query_values(Array) || []) << ['ticket', self.ticket]
    service_uri.to_s
  end

  def expired?
    lifetime = if consumed?
      CASino.config.service_ticket[:lifetime_consumed]
    else
      CASino.config.service_ticket[:lifetime_unconsumed]
    end
    (Time.now - (self.created_at || Time.now)) > lifetime
  end

  private
  def send_single_sign_out_notification
    notifier = SingleSignOutNotifier.new(self)
    notifier.notify
    true
  end
end
