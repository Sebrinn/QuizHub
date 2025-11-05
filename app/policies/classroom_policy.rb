class ClassroomPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    @user.admin? || @user.teacher? || @user.student?
  end

  def show?
    @user.admin? || @record.member?(@user)
  end

  def create?
    @user.teacher? || @user.admin?
  end

  def new?
    @user.teacher? || @user.admin?
  end

  def destroy?
    @user.admin? || (@user.teacher? && @record.teacher == @user)
  end

  def remove_student?
    @user.admin? || (@user.teacher? && @record.teacher == @user)
  end

  def join?
    @user.student? || @user.teacher? || @user.admin?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if @user.admin?
        @scope.all
      elsif @user.teacher?
        @scope.where(teacher: @user)
      elsif @user.student?
        @scope.joins(:students).where(classroom_memberships: { user_id: @user.id })
      else
        @scope.none
      end
    end
  end
end
