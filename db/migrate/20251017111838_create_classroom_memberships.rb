class CreateClassroomMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :classroom_memberships do |t|
      t.references :classroom, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :joined_at, null: false

      t.timestamps
    end

    # Unikalne połączenie (user_id, classroom_id) — odpowiada walidacji w modelu
    add_index :classroom_memberships, [ :user_id, :classroom_id ], unique: true
  end
end
