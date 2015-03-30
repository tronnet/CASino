require 'user_agent'
require 'casino/user'

class CASino::TicketGrantingTicket
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "ticket_granting_tickets"

  field :ticket, type: String
  field :user_agent, type: String
  field :awaiting_two_factor_authentication, type: Boolean, :default => false
  field :long_term, type: Boolean, :default => false

  validates :ticket, uniqueness: true

  belongs_to :user, :class_name => "CASino::User", :foreign_key=>"user_id"
  has_many :service_tickets, :class_name => "CASino::ServiceTicket", dependent: :destroy

  def self.find_by_ticket(ticket)
    self.where(ticket: ticket).first
  end

  def self.cleanup(user = nil)
    query = {
        :created_at.lt => CASino.config.two_factor_authenticator[:timeout].seconds.ago,
        :awaiting_two_factor_authentication => true
      }
    query[:user] = user unless user.nil?
    tickets = self.where(query)

    query = {
        :created_at.lt => CASino.config.two_factor_authenticator[:timeout].seconds.ago,
        :long_term => false
      }
    query[:user] = user unless user.nil?
    tickets += self.where(query)

    query = {:created_at.lt =>CASino.config.ticket_granting_ticket[:lifetime_long_term].seconds.ago}
    query[:user] = user unless user.nil?
    tickets += self.where(query)

    CASino::ServiceTicket.where(:ticket_granting_ticket.in => tickets).destroy_all
    _ids = tickets.collect do |ticket|
    	ticket._id
    end

    self.where(:_id.in => _ids).destroy_all
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
