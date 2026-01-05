class QuizPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    @user.admin? || record.classroom.member?(@user)
  end

  def show?
    if user.student?
      record.quiz_results.where(user: user).exists? || record.status == :finished
    else
      @user.admin? || record.classroom.member?(@user)
    end
  end

  def new?
    @user.admin? || (@user.teacher? && (record.classroom.nil? || record.classroom.teacher == @user))
  end

  def create?
    @user.admin? || (@user.teacher? && record.classroom.teacher == @user)
  end

  def edit?
    @user.admin? || (@user.teacher? && record.classroom.teacher == @user)
  end

  def update?
    @user.admin? || (@user.teacher? && record.classroom.teacher == @user)
  end

  def destroy?
    @user.admin? || (@user.teacher? && record.classroom.teacher == @user)
  end

def start?
  puts "=== DEBUG START POLICY ==="
  puts "User: #{@user.inspect}"
  puts "User role: #{@user.role}"
  puts "User student?: #{@user.student?}"
  puts "Record: #{@record.inspect}"
  puts "Classroom member?: #{@record.classroom.member?(@user)}"
  puts "Can be started?: #{@record.can_be_started?(@user)}"
  puts "=== END DEBUG ==="

  @user.admin? || (@user.student? && @record.classroom.member?(@user) && @record.can_be_started?(@user))
end

  def submit?
    solve?
  end

  def results?
    @user.admin? || (record.classroom.member?(@user) && (@user.teacher? || record.quiz_results.where(user: @user).exists?))
  end

  def activate?
    @user.admin? || (@user.teacher? && record.classroom.teacher == @user)
  end

  def deactivate?
    @user.admin? || (@user.teacher? && record.classroom.teacher == @user)
  end

def solve?
  return true if @user.admin?
  return false unless @user.student?
  return false unless @record.classroom.member?(@user)
  return false unless @record.quiz_results.active.exists?(user: @user)
  return false unless @record.active?

  if @record.time_limit && @record.time_limit > 0
    quiz_result = @record.quiz_results.active.find_by(user: @user)
    end_time = quiz_result.created_at + @record.time_limit.minutes
    return false if Time.current > end_time
  end

  true
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
        @scope.joins(:classroom).where(classrooms: { teacher_id: @user.id })
      elsif @user.student?
        @scope.joins(:classroom)
              .where(classrooms: {
                id: Classroom.joins(:classroom_memberships)
                            .where(classroom_memberships: { user_id: @user.id })
              })
      else
        @scope.none
      end
    end
  end
end
