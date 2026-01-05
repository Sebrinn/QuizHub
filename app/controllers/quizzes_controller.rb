class QuizzesController < ApplicationController
  before_action :set_classroom
  before_action :set_quiz, only: [ :start, :submit, :solve, :results, :show, :edit, :update, :destroy, :activate, :deactivate ]
  after_action :verify_authorized

  def new
    @quiz = @classroom.quizzes.new
    authorize @quiz
  end

  def create
    @quiz = @classroom.quizzes.new(quiz_params)
    @quiz.created_by = current_user
    authorize @quiz

    if @quiz.save
      redirect_to classroom_path(@classroom), notice: "Quiz został utworzony pomyślnie."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @quiz
  end

  def update
    authorize @quiz
    if @quiz.update(quiz_params)
      redirect_to classroom_quiz_path(@classroom, @quiz), notice: "Quiz został zaktualizowany."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    authorize @quiz
  end

  def destroy
    authorize @quiz
    @quiz.destroy
    redirect_to classroom_quizzes_path(@classroom), notice: "Quiz został usunięty."
  end

  def activate
    authorize @quiz
    @quiz.update(active: true)
    redirect_to classroom_quiz_path(@classroom, @quiz), notice: "Quiz został aktywowany."
  end

  def deactivate
    authorize @quiz
    @quiz.update(active: false)
    redirect_to classroom_quiz_path(@classroom, @quiz), notice: "Quiz został dezaktywowany."
  end

  def results
    set_classroom
    @quiz = @classroom.quizzes.find(params[:id])
    authorize @quiz

    @quiz_results = @quiz.quiz_results.includes(:user).order(created_at: :desc)

    if current_user.student? && @quiz.status != :finished
      @quiz_results = @quiz_results.where(user: current_user)
    end

    if @quiz_results.active.any?
      scores = @quiz_results.active.map { |r| (r.score.to_f / r.total) * 100 }
      @average_score = (scores.sum / scores.size).round(2)
      @best_score = scores.max.round(2)
      @worst_score = scores.min.round(2)
    end
  end

  def start
    authorize @quiz

    active_attempt = @quiz.quiz_results.active.find_by(user: current_user)
    if active_attempt
      redirect_to solve_classroom_quiz_path(@classroom, @quiz),
                  alert: "Masz już aktywne podejście do tego quizu."
      return
    end

    unless @quiz.can_be_started?(current_user)
      redirect_to classroom_path(@classroom), alert: "Nie możesz rozpocząć tego quizu."
      return
    end

    @quiz_result = @quiz.quiz_results.create!(
      user: current_user,
      score: 0,
      total: @quiz.total_max_score,
      status: :active
    )

    redirect_to solve_classroom_quiz_path(@classroom, @quiz), status: :see_other
  end

  def solve
    authorize @quiz

    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"


    @quiz_result = @quiz.quiz_results.active.find_by(user: current_user)

    unless @quiz_result
      redirect_to classroom_path(@classroom), alert: "Musisz najpierw rozpocząć quiz."
      return
    end

    if @quiz.time_limit && @quiz.time_limit > 0
      end_time = @quiz_result.created_at + @quiz.time_limit.minutes
      if Time.current > end_time
        redirect_to results_classroom_quiz_path(@classroom, @quiz),
                    alert: "Czas na rozwiązanie quizu upłynął."
        return
      end
    end

    @questions = @quiz.shuffle_questions ? @quiz.questions.shuffle : @quiz.questions
  end

  def submit
    authorize @quiz

    @quiz_result = @quiz.quiz_results.active.find_by(user: current_user)

    unless @quiz_result
      redirect_to classroom_path(@classroom), alert: "Nie znaleziono wyniku quizu."
      return
    end

    auto_score = calculate_score(params[:answers] || {})

    save_open_answers(params[:answers] || {}, @quiz_result)

      @quiz_result.update!(
        score: auto_score,
        original_score: auto_score
      )

    redirect_to results_classroom_quiz_path(@classroom, @quiz),
                notice: "Quiz został zakończony."
  end

  private

  def save_open_answers(answers_params, quiz_result)
    @quiz.questions.open_ended.each do |question|
      user_answer = answers_params[question.id.to_s].to_s.strip

      if user_answer.present?
        OpenAnswer.create!(
          question: question,
          user: current_user,
          quiz_result: quiz_result,
          content: user_answer,
          status: :pending
        )
      end
    end
  end

  def set_classroom
    @classroom = Classroom.find(params[:classroom_id])
  end

  def set_quiz
    puts "=== DEBUG SET_QUIZ ==="
    puts "params[:id]: #{params[:id]}"
    puts "params[:classroom_id]: #{params[:classroom_id]}"
    puts "@classroom: #{@classroom.inspect}"

    @quiz = @classroom.quizzes.find(params[:id])
    puts "@quiz: #{@quiz.inspect}"
    puts "=== END DEBUG SET_QUIZ ==="
  rescue ActiveRecord::RecordNotFound => e
    puts "ERROR in set_quiz: #{e.message}"
    @quiz = nil
  end

  def quiz_params
    params.require(:quiz).permit(:title, :description, :start_time, :end_time, :time_limit, :shuffle_questions, :active)
  end

  def calculate_score(answers_params)
    score = 0

    @quiz.questions.each do |question|
      if question.multiple_choice?
        user_answer_ids = Array(answers_params[question.id.to_s]).map(&:to_i)
        correct_answer_ids = question.answers.where(correct: true).pluck(:id)

        if user_answer_ids.sort == correct_answer_ids.sort
          score += 1
        end
      end
    end

    score
  end
end
