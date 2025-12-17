class OpenAnswer < ApplicationRecord
  belongs_to :question
  belongs_to :user
  belongs_to :quiz_result

  validates :content, presence: true, if: :submitted?

  # Punkty za odpowiedź (uzupełniane przez nauczyciela)
  validates :score, numericality: {
    greater_than_or_equal_to: 0,
    allow_nil: true
  }

  enum :status, {
    pending: 0,      # Oczekuje na ocenę
    graded: 1        # Ocenione
  }

  scope :ungraded, -> { where(status: :pending) }
  scope :graded, -> { where(status: :graded) }

  def submitted?
    content.present?
  end

  def max_score
    question.max_score || 1
  end
end
