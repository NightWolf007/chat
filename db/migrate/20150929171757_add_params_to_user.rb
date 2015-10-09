class AddParamsToUser < ActiveRecord::Migration
  def change
    add_column :users, :gender, :boolean, null: false
    add_column :users, :birthday, :date, null: false
    add_column :users, :location, :string, null: false
  end
end
