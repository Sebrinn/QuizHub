# app/policies/open_answer_policy.rb
class OpenAnswerPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def show?
    # Uczeń może zobaczyć tylko swoje odpowiedzi
    # Nauczyciel może zobaczyć odpowiedzi uczniów ze swojej klasy
    @user.admin? ||
    (@user.teacher? && @record.question.quiz.classroom.teacher == @user) ||
    (@user.student? && @record.user == @user)
  end

  def grade?
    # Tylko nauczyciel/admin może oceniać odpowiedzi otwarte
    @user.admin? ||
    (@user.teacher? && @record.question.quiz.classroom.teacher == @user)
  end

  def update?
    grade? # Aktualizacja to to samo co ocenianie
  end

  def destroy?
    # Tylko admin lub nauczyciel może usuwać odpowiedzi
    @user.admin? ||
    (@user.teacher? && @record.question.quiz.classroom.teacher == @user)
  end

  def request_review?
    # Uczeń może żądać ponownej oceny swojej odpowiedzi
    # Nauczyciel też może to zrobić
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
        # Nauczyciele widzą odpowiedzi z quizów w swoich klasach
        @scope.joins(question: { quiz: :classroom })
              .where(classrooms: { teacher_id: @user.id })
      elsif @user.student?
        # Studenci widzą tylko swoje odpowiedzi
        @scope.where(user_id: @user.id)
      else
        @scope.none
      end
    end
  end
end
