class QuizResult < ApplicationRecord
  belongs_to :quiz
  belongs_to :user

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
end
