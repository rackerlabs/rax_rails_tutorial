class CloudModelBase
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  # declare attributes in subclass with attr_accessor
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end

  def self.compute
    @compute ||= Fog::Compute.new(
      :provider           => 'Rackspace',
      :rackspace_api_key  => APP_CONFIG[:rackspace_api_key],
      :version => :v2,
      :rackspace_username => APP_CONFIG[:rackspace_username])
  end

end