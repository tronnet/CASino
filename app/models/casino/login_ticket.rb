class CASino::LoginTicket
	include Mongoid::Document
	include Mongoid::Timestamps

	store_in collection: "login_tickets"

	field :ticket, type: String

  validates :ticket, uniqueness: true

  def self.cleanup
    self.delete_all(['created_at < ?', CASino.config.login_ticket[:lifetime].seconds.ago])
  end

  def to_s
    self.ticket
  end
end
