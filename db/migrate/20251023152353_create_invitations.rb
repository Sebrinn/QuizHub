# db/migrate/xxx_create_invitations.rb
class CreateInvitations < ActiveRecord::Migration[7.0]
  def change
    create_table :invitations do |t|
      t.string :email, null: false
      t.string :token, null: false
      t.integer :role, default: 0
      t.integer :status, default: 0
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.datetime :expires_at

      t.timestamps
    end
    add_index :invitations, :token, unique: true
    add_index :invitations, :email
  end
end
