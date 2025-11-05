class AddTimingToQuizzes < ActiveRecord::Migration[8.0]
  def change
    add_column :quizzes, :active, :boolean, default: false
    add_column :quizzes, :start_time, :datetime
    add_column :quizzes, :end_time, :datetime
    add_column :quizzes, :time_limit, :integer # w minutach, 0 = bez limitu
    add_column :quizzes, :shuffle_questions, :boolean, default: false
  end
end
