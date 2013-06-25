class Flavor < CloudModelBase

  def self.find_by_id(id)
    compute.flavors.get(id)
  end

  def self.all
    compute.flavors
  end

end