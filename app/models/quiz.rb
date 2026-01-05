class Quiz < ApplicationRecord
  belongs_to :classroom
  belongs_to :created_by, class_name: "User", foreign_key: "created_by_id"

  has_many :questions, dependent: :destroy
  has_many :quiz_results, dependent: :destroy

  validates :title, presence: true, length: { minimum: 3, maximum: 200 }
  validates :description, presence: true
  validate :end_time_after_start_time

  scope :active, -> { where(active: true) }
  scope :upcoming, -> { where("start_time > ?", Time.current) }
  scope :ongoing, -> { where(active: true).where("start_time <= ? AND end_time >= ?", Time.current, Time.current) }
  scope :finished, -> { where("end_time < ?", Time.current) }

  def status
    return :draft unless active?
    return :upcoming if start_time > Time.current
    return :ongoing if start_time <= Time.current && end_time >= Time.current
    return :finished if end_time < Time.current
    :draft
  end

  def can_be_started?(user)
    return false unless active?
    return false if quiz_results.active.exists?(user: user)
    return false if quiz_results.inactive.exists?(user: user)

    if start_time && end_time
      Time.current.between?(start_time, end_time)
    else
      active?
    end
  end

  def time_remaining_for_user(user)
    return nil unless time_limit && time_limit > 0

    quiz_result = quiz_results.find_by(user: user)
    return nil unless quiz_result

    end_time = quiz_result.created_at + time_limit.minutes
    [ 0, (end_time - Time.current).to_i ].max
  end

  def total_max_score
    questions.sum { |question| question.max_score }
  end

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end
end
