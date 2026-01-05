class QuestionPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    @user.admin? || record.quiz.classroom.member?(@user)
  end

  def show?
    @user.admin? || record.quiz.classroom.member?(@user)
  end

  def new?
    @user.admin? || (@user.teacher? && record.quiz.classroom.teacher == @user)
  end

  def create?
    @user.admin? || (@user.teacher? && record.quiz.classroom.teacher == @user)
  end

  def edit?
    @user.admin? || (@user.teacher? && record.quiz.classroom.teacher == @user)
  end

  def update?
    @user.admin? || (@user.teacher? && record.quiz.classroom.teacher == @user)
  end

  def destroy?
    @user.admin? || (@user.teacher? && record.quiz.classroom.teacher == @user)
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
        @scope.joins(quiz: :classroom).where(classrooms: { teacher_id: @user.id })
      elsif @user.student?
        @scope.joins(quiz: { classroom: :classroom_memberships })
              .where(classroom_memberships: { user_id: @user.id })
      else
        @scope.none
      end
    end
  end
end
