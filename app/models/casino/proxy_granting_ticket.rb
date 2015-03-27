class CASino::ProxyGrantingTicket
	include Mongoid::Document
	include Mongoid::Timestamps

	attr_accessible :iou, :ticket, :pgt_url

	store_in collection: "proxy_granting_tickets"

	field :ticket, type: String
	field :iou, type: String
	field :pgt_url, type: String
	field :granter_type, type: String

  validates :ticket, uniqueness: true
  validates :iou, uniqueness: true
  
  belongs_to :granter, polymorphic: true
  has_and_belongs_to_many :proxy_tickets, :class_name => "CASino::ProxyTicket", dependent: :destroy, inverse_of: :proxy_granting_ticket

  def compact
  	self.proxy_tickets.compact
  end
end