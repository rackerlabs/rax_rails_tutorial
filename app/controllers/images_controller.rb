class ImagesController < ApplicationController

  def index
    @images = Image.snapshots
  end

  def new
    @image = Image.new
  end

  def create
    @image = Image.new(params[:image])
    if @image.valid?
      image = Image.create(params[:image])
      flash[:notice] = "Image created"
      redirect_to images_path
    else
      render :action => :new
    end
  end

  def destroy
    @image = Image.find_by_id(params[:id])
    Image.delete(@image.id)
    flash[:notice] = "Image destroyed"
    redirect_to images_path
  end

end