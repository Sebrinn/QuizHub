class AddStatusToQuizResults < ActiveRecord::Migration[8.0]
  def change
    add_column :quiz_results, :status, :integer, default: 0
    add_index :quiz_results, :status
  end
end
