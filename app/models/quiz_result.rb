class QuizResult < ApplicationRecord
  belongs_to :quiz
  belongs_to :user
  has_many :open_answers, dependent: :destroy

  enum :status, {
    active: 0,      # Aktywne podejście
    inactive: 1,    # Dezaktywowane (nauczyciel)
    retaken: 2      # Zastąpione nowym podejściem
  }

  scope :active, -> { where(status: :active) }
  scope :for_student, ->(student) { where(user: student) }

  def deactivate!
    update!(status: :inactive)
  end

  def mark_as_retaken!
    update!(status: :retaken)
  end

  def calculate_final_score
    closed_score = self.original_score || self.score

    open_score = open_answers.graded.sum(:score).to_i

    new_total_score = closed_score + open_score

    if new_total_score != self.score
      update_column(:score, new_total_score)
    end
  end

  def has_ungraded_open_answers?
    open_answers.ungraded.any?
  end
end
