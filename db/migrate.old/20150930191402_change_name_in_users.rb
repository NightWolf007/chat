class ChangeNameInUsers < ActiveRecord::Migration
  def change
    change_column :users, :name, :string, :null => false, :default => ""
  end
end
