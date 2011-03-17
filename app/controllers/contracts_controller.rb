# Sequreisp - Copyright 2010, 2011 Luciano Ruete
#
# This file is part of Sequreisp.
#
# Sequreisp is free software: you can redistribute it and/or modify
# it under the terms of the GNU Afero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Sequreisp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Afero General Public License for more details.
#
# You should have received a copy of the GNU Afero General Public License
# along with Sequreisp.  If not, see <http://www.gnu.org/licenses/>.

class ContractsController < ApplicationController
  before_filter :require_user
  permissions :contracts
  # GET /contracts
  # GET /contracts.xml
  def index
    params[:search] ||= {}
    params[:search][:order] ||= 'ascend_by_ip_custom'
    @search = Contract.search(params[:search])
    @contracts = @search.paginate(:page => params[:page],:per_page => 10)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @contracts }
      format.csv do
        @contracts = Contract.search(params[:search])
        csv_string = FasterCSV.generate(:col_sep => ";") do |csv|
          # header row
          csv << [
            t('activerecord.attributes.contract.client'),
            t('activerecord.attributes.client.email'),
            t('activerecord.attributes.client.address'),
            t('activerecord.attributes.client.phone'),
            t('activerecord.attributes.client.phone_mobile'),
            t('activerecord.attributes.client.details'),
            t('activerecord.attributes.contract.plan'),
            t('activerecord.attributes.contract.ip'),
            t('activerecord.attributes.contract.forwarded_ports'),
            t('activerecord.attributes.contract.state')
          ]
  
          # data rows
          @contracts.each do |c|
            csv << [
              c.client.name,
              c.client.email,
              c.client.address,
              c.client.phone,
              c.client.phone_mobile,
              c.client.details,
              c.plan.name,
              c.ip,
              c.forwarded_ports.collect{ |fp| "[#{fp.provider.name}]#{fp.public_port}=>#{fp.private_port}" }.join("|"),
              c.state 
            ]
          end
        end
        # send it to the browsah
        send_data csv_string,
                :type => 'text/csv; charset=UTF-8; header=present',
                :disposition => "attachment; filename=sequreisp_contracts_#{Time.now.strftime("%Y-%m-%d")}.csv"
      end
    end
  end

  # GET /contracts/1
  # GET /contracts/1.xml
  def show
    @contract = object
    render :action => "edit"
  end

  # GET /contracts/new
  # GET /contracts/new.xml
  def new
    @contract = Contract.new
    @contract.client_id = params[:client_id] unless params[:client_id].nil?
    @contract.ceil_dfl_percent = 70

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @contract }
    end
  end

  # GET /contracts/1/edit
  def edit
    @contract = object
  end

  # POST /contracts
  # POST /contracts.xml
  def create
    @contract = Contract.new(params[:contract])

    respond_to do |format|
      if @contract.save
        flash[:notice] = t 'controllers.successfully_created'
        format.html { redirect_back_from_edit_or_to(contracts_path) }
        format.xml  { render :xml => @contract, :status => :created, :location => @contract }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @contract.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /contracts/1
  # PUT /contracts/1.xml
  def update
    @contract = object

    respond_to do |format|
      if @contract.update_attributes(params[:contract])
        flash[:notice] = t 'controllers.successfully_updated'
        format.html { redirect_back_from_edit_or_to(contracts_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @contract.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /contracts/1
  # DELETE /contracts/1.xml
  def destroy
    @contract = object
    @contract.destroy

    respond_to do |format|
      format.html { redirect_to(contracts_url) }
      format.xml  { head :ok }
    end
  end
  def instant_rate
    @contract = object
    respond_to do |format|
      format.json { render :json => { :down => @contract.instant_rate_down, :up => @contract.instant_rate_up } }
    end 
  end
  private
  def object
    @object ||= Contract.find(params[:id])
  end
end
