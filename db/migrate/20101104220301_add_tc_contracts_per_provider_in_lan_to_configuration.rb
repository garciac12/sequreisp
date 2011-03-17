class AddTcContractsPerProviderInLanToConfiguration < ActiveRecord::Migration
  def self.up
    add_column :configurations, :tc_contracts_per_provider_in_lan, :boolean, :default => false
  end

  def self.down
    remove_column :configurations, :tc_contracts_per_provider_in_lan
  end
end
