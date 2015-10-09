class AddImageToUser < ActiveRecord::Migration
  def change
    add_column :users, :image, :string, default: nil
  end
end
