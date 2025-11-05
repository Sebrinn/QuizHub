# app/controllers/ai_questions_controller.rb
class AiQuestionsController < ApplicationController
  before_action :set_classroom
  before_action :set_quiz
  after_action :verify_authorized

  def new
    authorize @quiz, :edit?
    @ai_questions = ensure_questions_structure(session[:generated_questions] || [])
  end

  def create
    authorize @quiz, :edit?

    prompt = params[:prompt].to_s.strip
    count  = params[:count].to_i
    count = 1 if count <= 0

    # ✅ Inicjalizuj postęp w sesji
    session[:generation_progress] = {
      total: count,
      current: 0,
      status: "in_progress"
    }

    generator = OpenrouterAiGenerator.new
    generated_questions = []

    # ✅ UŻYJ PUBLICZNEJ METODY Z GENERATORA - NIE TWÓŻ WŁASNEJ
    count.times do |i|
      # ✅ Aktualizuj postęp PRZED generowaniem
      session[:generation_progress] = {
        total: count,
        current: i,
        status: "in_progress"
      }

      puts "Generating question #{i + 1}/#{count}"

      # ✅ UŻYJ PUBLICZNEJ METODY z generatora
      question = generator.generate_single_question(prompt, i + 1)
      generated_questions << question if question

      # ✅ Aktualizuj postęp PO wygenerowaniu
      session[:generation_progress] = {
        total: count,
        current: i + 1,
        status: i + 1 == count ? "completed" : "in_progress"
      }

      # Małe opóźnienie między requestami
      sleep(1) if count > 1 && i < count - 1
    end

    # Zapisz wygenerowane pytania w sesji
    session[:generated_questions] = generated_questions.map(&:deep_symbolize_keys)

    # ✅ Wyczyść postęp po zakończeniu
    session.delete(:generation_progress)

    @ai_questions = generated_questions
    render :new
  end

  def generating_status
    authorize @quiz, :edit?

    # Pobierz postęp z sesji
    progress = session[:generation_progress] || {
      total: 0,
      current: 0,
      status: "not_started"
    }

    render json: progress
  end

  def add_to_quiz
    authorize @quiz, :edit?

    begin
      question_data = JSON.parse(params[:question_data])
      question_index = params[:question_index].to_i

      # ✅ Upewnij się, że dane mają poprawną strukturę
      normalized_question = normalize_question_structure(question_data)

      @question = @quiz.questions.new(normalized_question)

      if @question.save
        # ✅ Usuń pytanie po indexie
        if session[:generated_questions] && session[:generated_questions][question_index]
          session[:generated_questions].delete_at(question_index)
        end

        # ✅ Upewnij się o strukturze przed renderowaniem
        @ai_questions = ensure_questions_structure(session[:generated_questions] || [])

        if @ai_questions.any?
          flash.now[:success] = "Pytanie dodane! Pozostało #{@ai_questions.size} pytań."
          render :new, status: :unprocessable_entity
        else
          session.delete(:generated_questions)
          redirect_to classroom_quiz_path(@classroom, @quiz),
                      notice: "Wszystkie pytania zostały dodane do quizu!"
        end
      else
        @ai_questions = ensure_questions_structure(session[:generated_questions] || [])
        flash.now[:error] = "Nie udało się dodać pytania: #{@question.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
    rescue JSON::ParserError => e
      @ai_questions = ensure_questions_structure(session[:generated_questions] || [])
      flash.now[:error] = "Niepoprawne dane pytania: #{e.message}"
      render :new, status: :unprocessable_entity
    end
  end

  def add_all_to_quiz
    authorize @quiz, :edit?

    added_count = 0
    error_count = 0

    if session[:generated_questions]
      session[:generated_questions].each do |question_data|
        # ✅ Upewnij się o strukturze przed zapisem
        normalized_question = normalize_question_structure(question_data)
        question = @quiz.questions.new(normalized_question)
        if question.save
          added_count += 1
        else
          error_count += 1
          Rails.logger.error "Failed to save question: #{question.errors.full_messages}"
        end
      end
    end

    session.delete(:generated_questions)

    if error_count.zero?
      redirect_to classroom_quiz_path(@classroom, @quiz),
                  notice: "Wszystkie #{added_count} pytań zostało dodanych do quizu!"
    else
      redirect_to classroom_quiz_path(@classroom, @quiz),
                  alert: "Dodano #{added_count} pytań, #{error_count} nie udało się dodać."
    end
  end

  def clear_questions
    authorize @quiz, :edit?
    session.delete(:generated_questions)
    redirect_to new_classroom_quiz_ai_questions_path(@classroom, @quiz),
                notice: "Wygenerowane pytania zostały wyczyszczone."
  end

  private

  # ✅ NOWA METODA: Upewnij się, że wszystkie pytania mają poprawną strukturę
  def ensure_questions_structure(questions)
    return [] unless questions.is_a?(Array)

    questions.map do |question|
      normalize_question_structure(question)
    end
  end

  # ✅ NOWA METODA: Normalizuj strukturę pytania (symbolize_keys)
  def normalize_question_structure(question_data)
    return question_data unless question_data.is_a?(Hash)

    # Konwertuj na symbole jeśli to stringi
    question = question_data.deep_symbolize_keys

    # Upewnij się, że answers_attributes istnieje i jest tablicą
    if question[:answers_attributes].nil? || !question[:answers_attributes].is_a?(Array)
      question[:answers_attributes] = []
    else
      # Upewnij się, że każda odpowiedź ma symbole
      question[:answers_attributes] = question[:answers_attributes].map do |answer|
        answer.is_a?(Hash) ? answer.deep_symbolize_keys : answer
      end
    end

    # Upewnij się, że content istnieje
    question[:content] ||= "Brak treści pytania"

    # Upewnij się, że question_type istnieje
    question[:question_type] ||= "multiple_choice"

    question
  end

  def set_classroom
    @classroom = Classroom.find(params[:classroom_id])
  end

  def set_quiz
    @quiz = @classroom.quizzes.find(params[:quiz_id])
  end
end
