class AddMessageToSites < ActiveRecord::Migration
  def self.up
    add_column :sites, :message, :text  
  end

  def self.down
    remove_column :sites, :message  
  end
end
