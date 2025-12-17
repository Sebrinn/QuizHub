class AddMaxScoreToQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :questions, :max_score, :integer
  end
end
