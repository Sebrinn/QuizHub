class Invitation < ApplicationRecord
  belongs_to :invited_by, class_name: "User"

  enum :role, { student: 0, teacher: 1 }
  enum :status, { pending: 0, accepted: 1, expired: 2, cancelled: 3 }

  before_create :generate_token, :set_expiration
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :email_not_already_registered
  validate :teacher_can_only_invite_students, on: :create

  def generate_token
    self.token = SecureRandom.urlsafe_base64(20)
  end

  def set_expiration
    self.expires_at = 7.days.from_now
  end

  def expired?
    status == "expired" || expires_at < Time.current
  end

def accept!(user)
  puts "=== ACCEPTING INVITATION ==="
  puts "Before - status: #{status}, user role: #{user.role}"

  self.update_columns(
    status: :accepted,
    updated_at: Time.current
  )

  user.update!(role: role.to_sym)

  self.reload

  puts "After - status: #{status}, user role: #{user.role}"
  puts "=== INVITATION ACCEPTED ==="

  true
rescue => e
  puts "ERROR accepting invitation: #{e.message}"
  false
end

  def cancel!
    update!(status: :cancelled)
  end

  private

  def email_not_already_registered
    if User.exists?(email: email)
      errors.add(:email, "jest już zarejestrowany w systemie")
    end
  end

  def teacher_can_only_invite_students
    if invited_by&.role == "teacher" && role != "student"
      errors.add(:role, "nauczyciele mogą zapraszać tylko uczniów")
    end
  end
end
