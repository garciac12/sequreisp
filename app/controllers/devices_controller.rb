class DevicesController < ApplicationController
  def index
    @search = Device.search(params[:search])
    @devices = @search.paginate(:page => params[:page], :per_page => 20)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @devices }
    end
  end

  def new
    @device = Device.new
  end

  def edit
    @device = object
  end

  def create
    @device = Device.new(params[:device])
    respond_to do |format|
      if @device.save
        flash[:notice] = t 'controllers.successfully_created'
        format.html { redirect_to(devices_path) }
        format.xml  { render :xml => @device, :status => :created, :location => @device }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @device.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @device = object
    respond_to do |format|
      if @device.update_attributes(params[:device])
        flash[:notice] = t 'controllers.successfully_updated'
        format.html { redirect_back_from_edit_or_to(devices_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @device.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    @device = Device.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @device }
    end
  end

  private

  def object
    Device.find(params[:id])
  end
end
