# app/models/question.rb
class Question < ApplicationRecord
  belongs_to :quiz
  has_many :answers, dependent: :destroy
  has_many :open_answers, dependent: :destroy

  validates :content, presence: true
  validates :question_type, presence: true, inclusion: { in: %w[multiple_choice open_ended] }

  # Walidacja dla pytań wielokrotnego wyboru
  validate :at_least_one_correct_answer, if: :multiple_choice?
  validate :at_least_two_answers, if: :multiple_choice?

  validates :max_score, numericality: { greater_than: 0 }, if: :open_ended?

  accepts_nested_attributes_for :answers,
                               allow_destroy: true,
                               reject_if: proc { |attrs| attrs["content"].blank? }

  scope :open_ended, -> { where(question_type: "open_ended") }

  def multiple_choice?
    question_type == "multiple_choice"
  end

  def open_ended?
    question_type == "open_ended"
  end

  def max_score
    self[:max_score] || (open_ended? ? 5 : 1)
  end

  private

  def at_least_one_correct_answer
    if answers.reject(&:marked_for_destruction?).none?(&:correct)
      errors.add(:base, "Pytanie wielokrotnego wyboru musi mieć przynajmniej jedną poprawną odpowiedź")
    end
  end

  def at_least_two_answers
    valid_answers = answers.reject(&:marked_for_destruction?).reject { |a| a.content.blank? }
    if valid_answers.size < 2
      errors.add(:base, "Pytanie wielokrotnego wyboru musi mieć przynajmniej dwie odpowiedzi")
    end
  end
end
