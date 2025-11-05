class CreateQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :questions do |t|
      t.text :content, null: false
      t.string :question_type, default: "multiple_choice", null: false
      t.references :quiz, null: false, foreign_key: true

      t.timestamps
    end
  end
end
