class AddConsumptionsToContract < ActiveRecord::Migration
  def self.up
    add_column :contracts, :consumption_down_prio, 'bigint unsigned', :default => 0
    add_column :contracts, :consumption_up_prio, 'bigint unsigned', :default => 0
    add_column :contracts, :consumption_down_dfl, 'bigint unsigned', :default => 0
    add_column :contracts, :consumption_up_dfl, 'bigint unsigned', :default => 0
  end

  def self.down
    remove_column :contracts, :consumption_up_dfl
    remove_column :contracts, :consumption_down_dfl
    remove_column :contracts, :consumption_up_prio
    remove_column :contracts, :consumption_down_prio
  end
end
