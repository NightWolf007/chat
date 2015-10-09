class AddParamsToUser < ActiveRecord::Migration
  def change
    add_column :users, :name, :string, :null => false

    add_column :users, :sex, :boolean, :null => false
    add_column :users, :birthday, :date, :null => false
    add_column :users, :location, :string, :null => false
  end
end
