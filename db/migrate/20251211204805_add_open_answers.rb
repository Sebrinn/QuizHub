class AddOpenAnswers < ActiveRecord::Migration[7.0]
  def change
    create_table :open_answers do |t|
      t.references :question, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :quiz_result, null: false, foreign_key: true
      t.text :content
      t.integer :score
      t.integer :status, default: 0
      t.text :teacher_feedback
      t.timestamps
    end
  end
end
