class CASino::ProxyGrantingTicket
	include Mongoid::Document
	include Mongoid::Timestamps

	store_in collection: "proxy_granting_tickets"

	field :ticket, type: String
	field :iou, type: String

  validates :ticket, uniqueness: true
  validates :iou, uniqueness: true
  
  belongs_to :granter, polymorphic: true
  has_many :proxy_tickets, dependent: :destroy
end
