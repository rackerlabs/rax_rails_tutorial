class ServersController < ApplicationController

  def index
    @servers = Server.all
  end

  def new
    @server = Server.new
  end

  def create
    @server = Server.new(params[:server])
    if @server.valid?
      server = Server.create(params[:server])
      flash[:notice] = "Server created"
      redirect_to servers_path
    else
      render :action => :new
    end
  end

  def destroy
    @server = Server.find_by_id(params[:id])
    Server.delete(@server.id)
    flash[:notice] = "Server destroyed"
    redirect_to servers_path
  end

end
