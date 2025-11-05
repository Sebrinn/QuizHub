# app/policies/question_policy.rb
class QuestionPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    # Dostęp do listy pytań mają tylko użytkownicy z dostępem do quizu
    @user.admin? || record.quiz.classroom.member?(@user)
  end

  def show?
    # Dostęp do szczegółów pytania mają tylko użytkownicy z dostępem do quizu
    @user.admin? || record.quiz.classroom.member?(@user)
  end

  def new?
    # Tylko admin lub nauczyciel prowadzący klasę może tworzyć pytania
    @user.admin? || (@user.teacher? && record.quiz.classroom.teacher == @user)
  end

  def create?
    # Tylko admin lub nauczyciel prowadzący klasę może tworzyć pytania
    @user.admin? || (@user.teacher? && record.quiz.classroom.teacher == @user)
  end

  def edit?
    # Tylko admin lub nauczyciel prowadzący klasę może edytować pytania
    @user.admin? || (@user.teacher? && record.quiz.classroom.teacher == @user)
  end

  def update?
    # Tylko admin lub nauczyciel prowadzący klasę może aktualizować pytania
    @user.admin? || (@user.teacher? && record.quiz.classroom.teacher == @user)
  end

  def destroy?
    # Tylko admin lub nauczyciel prowadzący klasę może usuwać pytania
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
        # Nauczyciele widzą pytania tylko ze swoich quizów
        @scope.joins(quiz: :classroom).where(classrooms: { teacher_id: @user.id })
      elsif @user.student?
        # Studenci widzą pytania tylko z quizów w klasach do których należą
        @scope.joins(quiz: { classroom: :classroom_memberships })
              .where(classroom_memberships: { user_id: @user.id })
      else
        @scope.none
      end
    end
  end
end
