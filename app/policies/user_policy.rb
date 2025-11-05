# app/policies/user_policy.rb
class UserPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    @user.admin? || @user.teacher?
  end

  def promote_to_teacher?
    @user.admin?
  end

  def demote_to_student?
    @user.admin?
  end

  def show?
    @user.admin? || @user == record
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
        @scope.where(role: [ :student, :teacher ])
      else
        @scope.where(id: @user.id)
      end
    end
  end
end
