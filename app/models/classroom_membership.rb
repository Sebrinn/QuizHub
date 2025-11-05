class ClassroomMembership < ApplicationRecord
  belongs_to :classroom
  belongs_to :user

  validates :user_id, uniqueness: { scope: :classroom_id, message: "is already a member of this classroom" }

  before_create :set_joined_at

  private

  def set_joined_at
    self.joined_at = Time.current
  end
end
