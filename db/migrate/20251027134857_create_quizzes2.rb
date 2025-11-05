class CreateQuizzes2 < ActiveRecord::Migration[8.0]
  def change
    drop_table :quizzes, if_exists: true
    create_table :quizzes do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.references :classroom, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
