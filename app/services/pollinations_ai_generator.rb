# app/services/pollinations_ai_generator.rb
class PollinationsAiGenerator
  POLLINATIONS_API_URL = "https://text.pollinations.ai/".freeze

  def generate_questions(prompt, count: 3)
    puts "🎯 Generating #{count} questions for: #{prompt}"

    questions = []
    count.times do |i|
      puts "🔧 Generating question #{i + 1}..."
      question = generate_single_question(prompt, i + 1)
      questions << question if question
      sleep(1) # Rate limiting
    end

    questions.any? ? questions : fallback_questions(prompt)
  end

  private

  def parse_simple_response(text, topic)
    # Bardzo proste parsowanie
    lines = text.split("\n").map(&:strip).reject(&:empty?)

    # Znajdź pierwszą sensowną linię jako pytanie
    question_line = lines.find { |line| line.length > 10 && !line.include?("<!") }

    if question_line
      {
        content: question_line.length > 100 ? question_line[0..100] + "..." : question_line,
        question_type: "multiple_choice",
        answers_attributes: [
          { content: "Poprawna odpowiedź dotycząca #{topic}", correct: true },
          { content: "Niepoprawna odpowiedź 1", correct: false },
          { content: "Niepoprawna odpowiedź 2", correct: false },
          { content: "Niepoprawna odpowiedź 3", correct: false }
        ]
      }
    else
      nil
    end
  end

  def generate_single_question(topic, question_number)
    simple_prompt = "Question about #{topic.split(',').first}"
    encoded_prompt = URI.encode_www_form_component(simple_prompt)

    # Usuń podwójny slash - użyj prawidłowego URL
    url = "https://text.pollinations.ai/#{encoded_prompt}"

    puts "🚀 API URL: #{url}"

    begin
      response = HTTParty.get(url, timeout: 30)

      puts "📡 Response Code: #{response.code}"

      if response.success?
        # Sprawdź czy to nie jest HTML
        if response.body.include?("<!DOCTYPE") || response.body.include?("<html")
          puts "❌ Got HTML instead of text"
          return nil
        end

        puts "📡 Response: #{response.body[0..200]}"
        parse_simple_response(response.body, topic)
      else
        puts "❌ API Error: #{response.code}"
        nil
      end
    rescue => e
      puts "❌ Rescue Error: #{e.message}"
      nil
    end
  end

  def build_prompt(topic, question_number)
    <<~PROMPT
      Stwórz pytanie wielokrotnego wyboru (ABCD) na temat: "#{topic}".

      WYMAGANY FORMAT:
      Pytanie: [treść pytania]
      A) [odpowiedź A]
      B) [odpowiedź B]
      C) [odpowiedź C]#{' '}
      D) [odpowiedź D]
      Poprawna: [A/B/C/D]

      Zasady:
      - Tylko jedna poprawna odpowiedź
      - Odpowiedzi konkretne i rzeczowe
      - Pytanie musi testować zrozumienie tematu
      - Unikaj pytań faktograficznych "kiedy?, gdzie?"
    PROMPT
  end

  def parse_question_response(text, original_topic)
    puts "=" * 50
    puts "📥 RAW API RESPONSE:"
    puts text
    puts "=" * 50

    lines = text.split("\n").map(&:strip).reject(&:empty?)

    puts "📝 PARSED LINES:"
    lines.each_with_index { |line, i| puts "#{i}: #{line}" }

    question_data = {
      content: extract_question(lines),
      question_type: "multiple_choice",
      answers_attributes: extract_answers(lines)
    }

    puts "🔍 EXTRACTED QUESTION DATA:"
    puts question_data.inspect

    # Walidacja
    if valid_question?(question_data)
      puts "✅ Valid question generated"
      question_data
    else
      puts "❌ Invalid question format - using fallback"
      nil
    end
  end

  def extract_question(lines)
    question_line = lines.find { |line| line.start_with?("Pytanie:") }

    if question_line
      # Usuń 'Pytanie:' i wyczyść
      question_line.gsub("Pytanie:", "").strip
    else
      # Szukaj linii z pytajnikiem
      question_candidate = lines.find { |line| line.include?("?") }
      if question_candidate
        # Usuń ewentualne numery itp.
        question_candidate.gsub(/^\d+\.\s*/, "").strip
      else
        # Fallback
        "Brak treści pytania"
      end
    end
  end

  def extract_question(lines)
    question_line = lines.find { |line| line.start_with?("Pytanie:") }

    if question_line
      question_line.gsub("Pytanie:", "").strip
    else
      # Użyj pierwszej linii która wygląda jak pytanie
      question_candidate = lines.find { |line| line.end_with?("?") }
      question_candidate || "Brak treści pytania"
    end
  end

  def extract_answers(lines)
    answers = []
    correct_letter = nil

    lines.each do |line|
      line = line.strip

      # Szukaj odpowiedzi A) B) C) D)
      if line.match(/^[A-D]\)/)
        letter = line[0]
        content = line.gsub(/^[A-D]\)\s*/, "").strip
        answers << { content: content, correct: false } if content.present?

      # Szukaj poprawnej odpowiedzi
      elsif line.downcase.start_with?("poprawna:")
        correct_letter = line.gsub(/poprawna:\s*/i, "").strip.upcase
      end
    end

    # Ustaw poprawną odpowiedź
    if correct_letter && answers.any?
      correct_index = [ "A", "B", "C", "D" ].index(correct_letter)
      answers[correct_index][:correct] = true if correct_index && answers[correct_index]
    end

    # Domyślne ustawienie jeśli brak poprawnej lub za mało odpowiedzi
    if answers.any?
      answers[0][:correct] = true if answers.none? { |a| a[:correct] }

      # Uzupełnij do 4 odpowiedzi jeśli potrzeba
      while answers.size < 4
        answers << { content: "Brak odpowiedzi", correct: false }
      end
    end

    answers
  end

  def valid_question?(question_data)
    question_data[:content].present? &&
    question_data[:answers_attributes].size == 4 &&
    question_data[:answers_attributes].any? { |a| a[:correct] }
  end

  def fallback_questions(topic)
    puts "🔄 Using fallback questions for: #{topic}"

    [
      {
        content: "Co jest główną zaletą programowania obiektowego w Ruby?",
        question_type: "multiple_choice",
        answers_attributes: [
          { content: "Łatwiejsze debugowanie kodu", correct: false },
          { content: "Enkapsulacja i modularność", correct: true },
          { content: "Szybsze wykonanie programu", correct: false },
          { content: "Mniejsze zużycie pamięci", correct: false }
        ]
      },
      {
        content: "Która metoda w Ruby służy do iteracji po kolekcji?",
        question_type: "multiple_choice",
        answers_attributes: [
          { content: "each", correct: true },
          { content: "loop", correct: false },
          { content: "iterate", correct: false },
          { content: "cycle", correct: false }
        ]
      }
    ]
  end
end
