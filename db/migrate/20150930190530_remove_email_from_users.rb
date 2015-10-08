class RemoveEmailFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :reset_password_token
    remove_column :users, :reset_password_sent_at

    remove_column :users, :confirmation_token
    remove_column :users, :confirmed_at
    remove_column :users, :confirmation_sent_at
    remove_column :users, :unconfirmed_email

    remove_column :users, :email
  end
end
