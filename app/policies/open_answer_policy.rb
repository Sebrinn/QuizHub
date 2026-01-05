class OpenAnswerPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def show?
    @user.admin? ||
    (@user.teacher? && @record.question.quiz.classroom.teacher == @user) ||
    (@user.student? && @record.user == @user)
  end

  def grade?
    @user.admin? ||
    (@user.teacher? && @record.question.quiz.classroom.teacher == @user)
  end

  def update?
    grade?
  end

  def destroy?
    @user.admin? ||
    (@user.teacher? && @record.question.quiz.classroom.teacher == @user)
  end

  def request_review?
    @user.admin? ||
    (@user.teacher? && @record.question.quiz.classroom.teacher == @user) ||
    (@user.student? && @record.user == @user && @record.graded?)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if @user.admin?
        @scope.all
      elsif @user.teacher?
        @scope.joins(question: { quiz: :classroom })
              .where(classrooms: { teacher_id: @user.id })
      elsif @user.student?
        @scope.where(user_id: @user.id)
      else
        @scope.none
      end
    end
  end
end
