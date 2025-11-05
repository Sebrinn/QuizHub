# app/controllers/quiz_results_controller.rb
class QuizResultsController < ApplicationController
  before_action :set_quiz_result
  after_action :verify_authorized

  def show
    authorize @quiz_result
    # Szczegóły rozwiązania - odpowiedzi użytkownika itp.
  end

  def deactivate
    authorize @quiz_result
    @quiz_result.deactivate!
    redirect_back fallback_location: results_classroom_quiz_path(@quiz_result.quiz.classroom, @quiz_result.quiz),
                  notice: "Rozwiązanie zostało dezaktywowane."
  end

  def allow_retake
    authorize @quiz_result

    # Deaktywujemy stare rozwiązanie
    @quiz_result.mark_as_retaken!

    # Usuwamy bieżący quiz_result dla tego użytkownika (jeśli istnieje)
    current_quiz_result = @quiz_result.quiz.quiz_results.active.find_by(user: @quiz_result.user)
    current_quiz_result&.destroy

    redirect_back fallback_location: results_classroom_quiz_path(@quiz_result.quiz.classroom, @quiz_result.quiz),
                  notice: "Użytkownik może teraz ponownie podejść do quizu."
  end

  private

  def set_quiz_result
    @quiz_result = QuizResult.find(params[:id])
  end
end
