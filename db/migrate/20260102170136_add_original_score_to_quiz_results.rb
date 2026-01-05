class AddOriginalScoreToQuizResults < ActiveRecord::Migration[8.0]
  def change
    add_column :quiz_results, :original_score, :integer
  end
end
