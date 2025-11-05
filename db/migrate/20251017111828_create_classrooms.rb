class CreateClassrooms < ActiveRecord::Migration[8.0]
  def change
    create_table :classrooms do |t|
      t.string :name, null: false
      t.text :description
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.string :invite_code, null: false

      t.timestamps
    end

    add_index :classrooms, :invite_code, unique: true
  end
end
