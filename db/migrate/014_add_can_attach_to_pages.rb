class AddCanAttachToPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :can_attach, :boolean, true
  end

  def self.down
    remove_column :pages, :can_attach  
  end
end
