class CASino::LoginTicket
	include Mongoid::Document
	include Mongoid::Timestamps

	store_in collection: "login_tickets"

	field :ticket, type: String

  validates :ticket, uniqueness: true

  def self.cleanup
  	self.where({
  			:created_at.lt => CASino.config.login_ticket[:lifetime].seconds.ago
  		}).destroy_all
  end

  def self.find_by_ticket(ticket)
  	self.where(ticket: ticket).first
  end

  def to_s
    self.ticket
  end
end
