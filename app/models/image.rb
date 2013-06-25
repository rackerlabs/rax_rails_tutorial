#THIS HAS CHANGED

class Image < CloudModelBase

  attr_accessor :name,
                :server_id

  validates :name, :presence => true
  validates :server_id, :presence => true


  def self.find_by_id(id)
    compute.images.get(id)
  end

  def self.all
    compute.images
  end

  def self.snapshots
    images = Image.all.partition {|img| img.metadata["image_type"] == "snapshot" }.first
    images.each {|img| img.reload }
  end

  def self.create(params)
    server = Server.find_by_id(params[:server_id])
    image = server.create_image params[:name]
  end

  def self.delete(id)
    compute.images.get(id).destroy
  end

end