class ClassroomsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_classroom, only: %i[show destroy remove_student]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def index
    @classrooms = policy_scope(Classroom).order(created_at: :desc)
  end

  def show
    authorize @classroom
    @quizzes = policy_scope(Quiz).where(classroom: @classroom).order(created_at: :desc)
  end

  def new
    authorize Classroom
    @classroom = current_user.taught_classrooms.build
  end

  def create
    authorize Classroom
    @classroom = current_user.taught_classrooms.build(classroom_params)

    if @classroom.save
      redirect_to @classroom, notice: "Klasa została utworzona pomyślnie."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @classroom
    @classroom.destroy
    redirect_to classrooms_path, notice: "Klasa została usunięta."
  end

  def join
    authorize Classroom
    @classroom = Classroom.find_by(invite_code: params[:invite_code].upcase)

    if @classroom.nil?
      redirect_to classrooms_path, alert: "Nie znaleziono klasy o podanym kodzie."
      return
    end

    if @classroom.students.include?(current_user)
      redirect_to @classroom, notice: "Już należysz do tej klasy."
    else
      @classroom.students << current_user
      redirect_to @classroom, notice: "Dołączono do klasy!"
    end
  end

  def remove_student
    @classroom = Classroom.find(params[:id])
    authorize @classroom

    student = User.find(params[:student_id])

    if @classroom.students.include?(student)
      @classroom.students.destroy(student)
      redirect_to @classroom, notice: "Uczeń #{student.full_name} został usunięty z klasy."
    else
      redirect_to @classroom, alert: "Nie znaleziono ucznia w tej klasie."
    end
  end

  private

  def set_classroom
    @classroom = Classroom.find(params[:id])
  end

  def classroom_params
    params.require(:classroom).permit(:name, :description)
  end
end
