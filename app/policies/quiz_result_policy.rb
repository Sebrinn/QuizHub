class QuizResultPolicy < ApplicationPolicy
  def manage?
    user.teacher? && record.quiz.classroom.teacher == user
  end

  def deactivate?
    manage? && record.active?
  end

  def allow_retake?
    manage? && record.user.student?
  end

  def view_details?
    manage? || record.user == user
  end
end
