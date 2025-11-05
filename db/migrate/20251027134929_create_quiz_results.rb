class CreateQuizResults < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_results do |t|
      t.references :quiz, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :score, default: 0
      t.integer :total, default: 0

      t.timestamps
    end
  end
end
