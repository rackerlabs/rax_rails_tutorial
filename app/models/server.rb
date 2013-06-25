class Server < CloudModelBase

  attr_accessor :name, :flavor_id, :image_id

  validates :name, :presence => true
  validates :flavor_id, :presence => true
  validates :image_id, :presence => true

  def self.all
    compute.servers
  end

  def self.find_by_id(id)
    compute.servers.get(id)
  end

  def self.create(params)
    compute.servers.create(:name => params[:name],
                           :flavor_id => params[:flavor_id],
                           :image_id => params[:image_id])
  end

  def self.delete(id)
    compute.servers.get(id).destroy
  end

end