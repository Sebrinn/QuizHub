# app/controllers/open_answers_controller.rb
class OpenAnswersController < ApplicationController
  before_action :set_open_answer
  after_action :verify_authorized

  def grade
    authorize @open_answer

    score = params[:open_answer][:score].to_i
    feedback = params[:open_answer][:feedback]

    if score.between?(0, @open_answer.max_score)
      @open_answer.update!(
        score: score,
        teacher_feedback: feedback,
        status: :graded
      )

      # Zaktualizuj wynik quizu
      @open_answer.quiz_result.calculate_final_score

      redirect_back fallback_location: results_classroom_quiz_path(
        @open_answer.question.quiz.classroom,
        @open_answer.question.quiz
      ), notice: "Odpowiedź została oceniona."
    else
      redirect_back fallback_location: results_classroom_quiz_path(
        @open_answer.question.quiz.classroom,
        @open_answer.question.quiz
      ), alert: "Wynik musi być między 0 a #{@open_answer.max_score}."
    end
  end

  def request_review
    authorize @open_answer

    if @open_answer.graded?
      @open_answer.update!(status: :pending)

      redirect_back fallback_location: results_classroom_quiz_path(
        @open_answer.question.quiz.classroom,
        @open_answer.question.quiz
      ), notice: "Zażądano ponownej oceny odpowiedzi."
    else
      redirect_back fallback_location: results_classroom_quiz_path(
        @open_answer.question.quiz.classroom,
        @open_answer.question.quiz
      ), alert: "Ta odpowiedź nie została jeszcze oceniona."
    end
  end

  private

  def set_open_answer
    @open_answer = OpenAnswer.find(params[:id])
  end
end
