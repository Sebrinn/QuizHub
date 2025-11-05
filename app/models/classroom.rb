class Classroom < ApplicationRecord
  belongs_to :teacher, class_name: "User", foreign_key: "teacher_id"

  has_many :classroom_memberships, dependent: :destroy
  has_many :students, through: :classroom_memberships, source: :user
  has_many :quizzes, dependent: :destroy

  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :invite_code, presence: true, uniqueness: true

  before_validation :generate_invite_code, on: :create

  def member?(user)
    teacher == user || students.include?(user)
  end

  def students_count
    students.count
  end

  private

  def generate_invite_code
    self.invite_code = loop do
      code = SecureRandom.alphanumeric(8).upcase
      break code unless Classroom.exists?(invite_code: code)
    end
  end
end
