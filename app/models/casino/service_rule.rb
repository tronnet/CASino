
class CASino::ServiceRule
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "service_rules"

  field :enabled, type: Boolean, :default => true
  field :order, type: Integer, :default => 10
  field :regex, type: Boolean, :default => false
  field :name, type: String
  field :url, type: String

  validates :name, presence: true
  validates :url, uniqueness: true, presence: true

  def self.allowed?(service_url)
    rules = self.where(enabled: true).to_a
    if rules.empty?
      true
    else
      rules.any? { |rule| rule.allows?(service_url) }
    end
  end

  def allows?(service_url)
    if self.regex?
      regex = Regexp.new self.url, true
      if regex =~ service_url
        return true
      end
    elsif self.url == service_url
      return true
    end
    false
  end
end
