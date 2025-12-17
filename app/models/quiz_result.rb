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
    auto_score = self.score # Wynik z pytań zamkniętych
    manual_score = open_answers.graded.sum(:score).to_i # Punkty za pytania otwarte

    # Aktualizuj tylko jeśli mamy nowe punkty z pytań otwartych
    if manual_score > 0 && auto_score + manual_score != self.score
      update_column(:score, auto_score + manual_score)
    end
  end

  def has_ungraded_open_answers?
    open_answers.ungraded.any?
  end
end
