class AddLockedToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :locked, :boolean  
  end

  def self.down
    remove_column :pages, :locked  
  end
end
