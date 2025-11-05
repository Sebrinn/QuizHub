class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  after_initialize :set_default_role, if: :new_record?

  # Role enum
  enum :role, { student: 0, teacher: 1, admin: 2 }

  # Associations
  has_many :taught_classrooms, class_name: "Classroom", foreign_key: "teacher_id", dependent: :destroy
  has_many :classroom_memberships, dependent: :destroy
  has_many :enrolled_classrooms, through: :classroom_memberships, source: :classroom
  has_many :created_quizzes, class_name: "Quiz", foreign_key: "created_by_id", dependent: :destroy

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :role, presence: true

  # Callbacks
  after_initialize :set_default_role, if: :new_record?

  def full_name
    "#{first_name} #{last_name}"
  end

  def teacher?
    role == "teacher" || role == "admin"
  end

  def student?
    role == "student"
  end

  def admin?
    role == "admin"
  end

  private

private
  def set_default_role
    self.role ||= :student
  end
end
