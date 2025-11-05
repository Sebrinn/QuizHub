class CreateTemporaryAiQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :temporary_ai_questions do |t|
      t.string :session_id
      t.integer :quiz_id
      t.jsonb :question_data

      t.timestamps
    end
  end
end
