# app/controllers/ai_questions_controller.rb
class AiQuestionsController < ApplicationController
  before_action :set_classroom
  before_action :set_quiz
  before_action :set_generation_key
  after_action :verify_authorized

  def new
    authorize @quiz, :edit?
    @ai_questions = load_questions_from_cache || []
    puts "DEBUG: Loaded #{@ai_questions.size} questions from cache for key: #{@generation_key}"
  end

  def create
    authorize @quiz, :edit?

    prompt = params[:prompt].to_s.strip
    count  = params[:count].to_i
    count = 1 if count <= 0

    puts "DEBUG: Starting generation - key: #{@generation_key}, count: #{count}"

    save_progress_to_cache({
      total: count,
      current: 0,
      status: "in_progress"
    })

    generator = OpenrouterAiGenerator.new
    generated_questions = []

    count.times do |i|
      save_progress_to_cache({
        total: count,
        current: i,
        status: "in_progress"
      })

      puts "DEBUG: Generating question #{i + 1}/#{count}"

      question = generator.generate_single_question(prompt, i + 1)
      generated_questions << question if question

      save_progress_to_cache({
        total: count,
        current: i + 1,
        status: i + 1 == count ? "completed" : "in_progress"
      })

      sleep(1) if count > 1 && i < count - 1
    end

    save_questions_to_cache(generated_questions)

    clear_progress_from_cache

    puts "DEBUG: Generation completed, saved #{generated_questions.size} questions to cache"

    @ai_questions = generated_questions
    render :new
  end

  def generating_status
    authorize @quiz, :edit?

    progress = load_progress_from_cache || {
      total: 0,
      current: 0,
      status: "not_started"
    }

    puts "DEBUG generating_status: #{progress.inspect} (key: #{@generation_key})"

    render json: progress
  end

  def add_to_quiz
    authorize @quiz, :edit?

    begin
      question_data = JSON.parse(params[:question_data])
      question_index = params[:question_index].to_i

      normalized_question = normalize_question_structure(question_data)
      @question = @quiz.questions.new(normalized_question)

      if @question.save
        questions = load_questions_from_cache || []
        if questions[question_index]
          questions.delete_at(question_index)
          save_questions_to_cache(questions)
          puts "DEBUG: Removed question #{question_index}, #{questions.size} remaining"
        end

        @ai_questions = load_questions_from_cache || []

        if @ai_questions.any?
          flash.now[:success] = "Pytanie dodane! Pozostało #{@ai_questions.size} pytań."
          render :new, status: :unprocessable_entity
        else
          clear_questions_from_cache
          redirect_to classroom_quiz_path(@classroom, @quiz),
                      notice: "Wszystkie pytania zostały dodane do quizu!"
        end
      else
        @ai_questions = load_questions_from_cache || []
        flash.now[:error] = "Nie udało się dodać pytania: #{@question.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
    rescue JSON::ParserError => e
      @ai_questions = load_questions_from_cache || []
      flash.now[:error] = "Niepoprawne dane pytania: #{e.message}"
      render :new, status: :unprocessable_entity
    end
  end

  def add_all_to_quiz
    authorize @quiz, :edit?

    added_count = 0
    error_count = 0

    questions = load_questions_from_cache || []
    puts "DEBUG: Adding all #{questions.size} questions to quiz"

    if questions.any?
      questions.each do |question_data|
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

    clear_questions_from_cache

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

    puts "DEBUG: Clearing questions for key: #{@generation_key}"
    clear_questions_from_cache

    redirect_to new_classroom_quiz_ai_questions_path(@classroom, @quiz),
                notice: "Wygenerowane pytania zostały wyczyszczone."
  end

  private

  def ensure_questions_structure(questions)
    return [] unless questions.is_a?(Array)

    questions.map do |question|
      normalize_question_structure(question)
    end
  end

  def normalize_question_structure(question_data)
    return question_data unless question_data.is_a?(Hash)

    question = question_data.deep_symbolize_keys

    if question[:answers_attributes].nil? || !question[:answers_attributes].is_a?(Array)
      question[:answers_attributes] = []
    else
      question[:answers_attributes] = question[:answers_attributes].map do |answer|
        answer.is_a?(Hash) ? answer.deep_symbolize_keys : answer
      end
    end

    question[:content] ||= "Brak treści pytania"
    question[:question_type] ||= "multiple_choice"

    question
  end

  def set_classroom
    @classroom = Classroom.find(params[:classroom_id])
  end

  def set_quiz
    @quiz = @classroom.quizzes.find(params[:quiz_id])
  end

  def set_generation_key
    @generation_key = "ai_generation_user_#{current_user.id}_quiz_#{@quiz.id}"
    puts "DEBUG: Generation key set to: #{@generation_key}"
  end


  def save_progress_to_cache(progress)
    Rails.cache.write("#{@generation_key}_progress", progress, expires_in: 1.hour)
    puts "DEBUG: Progress saved to cache: #{progress}"

    test_read = Rails.cache.read("#{@generation_key}_progress")
    puts "🔍 DEBUG: Immediately after save, read back: #{test_read}"
  end

  def load_progress_from_cache
    progress = Rails.cache.read("#{@generation_key}_progress")
    puts "DEBUG: Progress loaded from cache: #{progress}"
    progress
  end

  def clear_progress_from_cache
    Rails.cache.delete("#{@generation_key}_progress")
  end

  def save_questions_to_cache(questions)
    Rails.cache.write("#{@generation_key}_questions", questions, expires_in: 1.hour)
  end

  def load_questions_from_cache
    Rails.cache.read("#{@generation_key}_questions")
  end

  def clear_questions_from_cache
    Rails.cache.delete("#{@generation_key}_questions")
  end
end
