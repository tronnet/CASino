require 'user_agent'

class CASino::TicketGrantingTicket
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "ticket_granting_tickets"

  field :ticket, type: String
  field :user_agent, type: String
  field :awaiting_two_factor_authentication, type: Boolean, :default => false
  field :long_term, type: Boolean, :default => false

  validates :ticket, uniqueness: true

  belongs_to :user
  has_many :service_tickets, dependent: :destroy

  def self.cleanup(user = nil)
    if user.nil?
      base = self
    else
      base = user.ticket_granting_tickets
    end
    tickets = Array.new
    tickets += base.where({
    		:created_at.lt => CASino.config.two_factor_authenticator[:timeout].seconds.ago,
    		:awaiting_two_factor_authentication => true
    	})

    tickets += base.where({
    		:created_at.lt => CASino.config.two_factor_authenticator[:timeout].seconds.ago,
    		:long_term => false
    	})

    tickets += base.where({
    		:created_at.lt =>CASino.config.ticket_granting_ticket[:lifetime_long_term].seconds.ago
    	})

    CASino::ServiceTicket.where(ticket_granting_ticket: tickets).destroy_all
    _ids = tickets.collect do |ticket|
    	tickets._id
    end
    base.where(_id: _ids).destroy_all
  end

  def browser_info
    unless self.user_agent.blank?
      user_agent = UserAgent.parse(self.user_agent)
      if user_agent.platform.nil?
        "#{user_agent.browser}"
      else
        "#{user_agent.browser} (#{user_agent.platform})"
      end
    end
  end

  def same_user?(other_ticket)
    if other_ticket.nil?
      false
    else
      other_ticket.user_id == self.user_id
    end
  end

  def expired?
    if awaiting_two_factor_authentication?
      lifetime = CASino.config.two_factor_authenticator[:timeout]
    elsif long_term?
      lifetime = CASino.config.ticket_granting_ticket[:lifetime_long_term]
    else
      lifetime = CASino.config.ticket_granting_ticket[:lifetime]
    end
    (Time.now - (self.created_at || Time.now)) > lifetime
  end
end
