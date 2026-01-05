class InvitationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    @user.admin? || @user.teacher?
  end

  def show?
    true # Dostępne dla wszystkich (do rejestracji)
  end

  def new?
    @user.admin? || @user.teacher?
  end

  def create?
    @user.admin? || @user.teacher?
  end

  def destroy?
    @user.admin? || (@user.teacher? && record.invited_by == @user)
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
        @scope.where(invited_by: @user)
      else
        @scope.none
      end
    end
  end
end
