# app/controllers/questions_controller.rb
class QuestionsController < ApplicationController
  before_action :set_classroom
  before_action :set_quiz
  before_action :set_question, only: [ :edit, :update, :destroy ]
  after_action :verify_authorized

  def new
    @question = @quiz.questions.new
    2.times { @question.answers.build }
    authorize @question
  end

  def edit
    authorize @question
    if @question.multiple_choice?
      @question.answers.build
    end
  end

  def create
    @question = @quiz.questions.new(question_params)
    authorize @question

    if @question.save
      redirect_to classroom_quiz_path(@classroom, @quiz), notice: "Pytanie zostało dodane."
    else
      (2 - @question.answers.size).times { @question.answers.build } if @question.answers.size < 2
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @question
    if @question.update(question_params)
      redirect_to  edit_classroom_quiz_question_path(@classroom, @quiz, @question), notice: "Pytanie zostało zaktualizowane."
    else
      @question.answers.build if @question.multiple_choice?
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @question
    @question.destroy
    redirect_to classroom_quiz_path(@classroom, @quiz), notice: "Pytanie zostało usunięte."
  end

  private

  def set_classroom
    @classroom = Classroom.find(params[:classroom_id])
  end

  def set_quiz
    @quiz = @classroom.quizzes.find(params[:quiz_id])
    authorize @quiz, :show?
  end

  def set_question
    @question = @quiz.questions.find(params[:id])
  end

  def question_params
    params.require(:question).permit(
      :content,
      :question_type,
      answers_attributes: [ :id, :content, :correct, :_destroy ]
    )
  end
end
