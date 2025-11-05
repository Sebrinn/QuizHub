class CreateQuizzes < ActiveRecord::Migration[8.0]
  def change
    create_table :quizzes do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.references :classroom, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :quizzes, [ :classroom_id, :title ], unique: true
  end
end
