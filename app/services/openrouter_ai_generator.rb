class OpenrouterAiGenerator
  API_URL = "https://openrouter.ai/api/v1/chat/completions".freeze

  def initialize(api_key = Rails.application.credentials.openrouter[:api_key])
    @api_key = api_key
  end

  def generate_single_question(topic, question_number = 1, question_type = "multiple_choice")
    puts "TEST: Generating #{question_type} question #{question_number} for: #{topic}"

    response = call_openrouter_api(topic, question_number, question_type)
    puts "DEBUG: API status = #{response&.code}, body = #{response&.body[0..300]}"

    if response&.success?
      body = response.body.force_encoding("UTF-8")
      puts "API Success for question #{question_number}! Response length: #{body.length}"

      question_data = parse_ai_response(body, topic, question_type)
      question_data || create_fallback_question(topic, question_type)
    else
      puts "API Error for question #{question_number}"
      create_fallback_question(topic, question_type)
    end
  end

  def call_openrouter_api(topic, question_number = 1, question_type = "multiple_choice")
    headers = {
      "Authorization" => "Bearer #{@api_key}",
      "Content-Type" => "application/json",
      "HTTP-Referer" => "http://localhost:3000",
      "X-Title" => "QuizHub"
    }

    system_prompt = build_system_prompt(topic, question_type)

    body = {
      model: ENV.fetch("AI_MODEL_NAME", "kwaipilot/kat-coder-pro:free"),
      messages: [
        {
          role: "system",
          content: "Jesteś pomocnym asystentem tworzącym pytania quizowe. Zawsze odpowiadasz TYLKO w formacie JSON, bez żadnych dodatkowych znaczników czy tekstu. NIE używaj ```json ani żadnych innych znaczników."
        },
        {
          role: "user",
          content: system_prompt
        }
      ],
      max_tokens: 1000
    }

    HTTParty.post(API_URL, headers: headers, body: body.to_json, timeout: 30)
  end

  def build_system_prompt(topic, question_type)
    case question_type
    when "open_ended"
      <<~PROMPT
        Stwórz PYTANIE OTWARTE na temat: #{topic}

        PYTANIE OTWARTE: uczeń musi samodzielnie sformułować odpowiedź tekstową.

        ZWRÓĆ DANE W FORMACIE JSON:
        {
          "content": "treść pytania otwartego z znakiem zapytania",
          "question_type": "open_ended",
          "max_score": 5
        }

        WYMAGANIA DLA PYTANIA OTWARTEGO:
        - Pytanie musi być otwarte, wymagające samodzielnej odpowiedzi tekstowej
        - Pytanie powinno testować zrozumienie, analizę lub syntezę wiedzy
        - Unikaj pytań, na które można odpowiedzieć jednym słowem
        - Pytanie powinno zachęcać do rozwiniętej odpowiedzi
        - Maksymalna punktacja: 5 punktów (dostosuj w zależności od złożoności)
        - Przykłady dobrych pytań otwartych:
          * "Wyjaśnij proces fotosyntezy w roślinach, uwzględniając rolę chlorofilu..."
          * "Opisz wpływ rewolucji przemysłowej na strukturę społeczną w XIX wieku..."
          * "Porównaj zalety i wady programowania obiektowego z funkcjonalnym..."

        Stwórz UNIKALNE pytanie różniące się od poprzednich.

        TYLKO JSON, bez dodatkowego tekstu, bez znaczników kodu!
      PROMPT

    when "multiple_choice"
      <<~PROMPT
        Stwórz pytanie WIELOKROTNEGO WYBORU na temat: #{topic}

        ZWRÓĆ DANE W FORMACIE JSON:
        {
          "content": "treść pytania z znakiem zapytania",
          "question_type": "multiple_choice",
          "answers_attributes": [
            {"content": "treść odpowiedzi A", "correct": true/false},
            {"content": "treść odpowiedzi B", "correct": true/false},
            {"content": "treść odpowiedzi C", "correct": true/false},
            {"content": "treść odpowiedzi D", "correct": true/false}
          ]
        }

        WYMAGANIA:
        - Pytanie musi kończyć się znakiem zapytania
        - Dokładnie 4 odpowiedzi
        - Przynajmniej 1 poprawna odpowiedź (correct: true)
        - Treści odpowiedzi muszą być konkretne i sensowne
        - Unikaj odpowiedzi typu "żadna z powyższych" lub "wszystkie powyższe"
        - Stwórz UNIKALNE pytanie różniące się od poprzednich

        TYLKO JSON, bez dodatkowego tekstu, bez znaczników kodu!
      PROMPT

    else
      rand(2) == 0 ? build_system_prompt(topic, "multiple_choice") : build_system_prompt(topic, "open_ended")
    end
  end

  def create_fallback_question(topic, question_type = "multiple_choice")
    case question_type
    when "open_ended"
      {
        "content" => "Wyjaśnij w 3-5 zdaniach kluczowe koncepcje związane z tematem: #{topic}?",
        "question_type" => "open_ended",
        "max_score" => 5
      }
    else
      {
        "content" => "Pytanie o: #{topic}?",
        "question_type" => "multiple_choice",
        "answers_attributes" => [
          { "content" => "Poprawna odpowiedź", "correct" => true },
          { "content" => "Niepoprawna odpowiedź 1", "correct" => false },
          { "content" => "Niepoprawna odpowiedź 2", "correct" => false },
          { "content" => "Niepoprawna odpowiedź 3", "correct" => false }
        ]
      }
    end
  end

  def parse_ai_response(response_body, topic, expected_type)
    begin
      data = JSON.parse(response_body)
      ai_content = data.dig("choices", 0, "message", "content")

      puts "AI CONTENT:"
      puts ai_content

      return nil unless ai_content

      clean_content = clean_json_content(ai_content)
      puts "CLEANED CONTENT:"
      puts clean_content

      question_data = JSON.parse(clean_content)

      if question_data["question_type"] != expected_type
        puts "WARNING: Expected #{expected_type} but got #{question_data['question_type']}"
        question_data["question_type"] = expected_type
      end

      if valid_question_structure?(question_data, expected_type)
        puts "VALID #{expected_type.upcase} QUESTION STRUCTURE FOUND"
        question_data
      else
        puts "INVALID QUESTION STRUCTURE for #{expected_type}"
        nil
      end

    rescue JSON::ParserError => e
      puts "JSON Parse Error: #{e.message}"
      extract_json_from_text(ai_content, topic, expected_type)
    rescue => e
      puts "General Parse Error: #{e.message}"
      nil
    end
  end

  def valid_question_structure?(data, expected_type)
    return false unless data.is_a?(Hash)
    return false unless data["content"].is_a?(String) && data["content"].include?("?")

    case expected_type
    when "multiple_choice"
      return false unless data["question_type"] == "multiple_choice"
      return false unless data["answers_attributes"].is_a?(Array)
      return false unless data["answers_attributes"].size >= 4

      correct_answers = data["answers_attributes"].count { |a| a["correct"] == true }
      return false unless correct_answers >= 1

      data["answers_attributes"].all? { |a| a["content"].is_a?(String) && a["content"].length > 0 }

    when "open_ended"
      return false unless data["question_type"] == "open_ended"
      return false unless data["max_score"].is_a?(Integer) && data["max_score"] > 0
      true

    else
      false
    end
  end

  def extract_json_from_text(content, topic, expected_type)
    puts "Extracting JSON from text..."
    json_match = content.match(/\{.*\}/m)

    if json_match
      begin
        json_string = json_match[0]
        puts "EXTRACTED JSON:"
        puts json_string

        question_data = JSON.parse(json_string)
        question_data["question_type"] = expected_type

        if valid_question_structure?(question_data, expected_type)
          puts "VALID QUESTION STRUCTURE FROM EXTRACTED JSON"
          return question_data
        end
      rescue JSON::ParserError => e
        puts "Extracted JSON parse error: #{e.message}"
      end
    end

    puts "Using structured fallback parsing..."
    structured_fallback(content, topic, expected_type)
  end

  def structured_fallback(content, topic, expected_type)
    case expected_type
    when "multiple_choice"
      content_match = content.match(/"content":\s*"([^"]+)"/)
      question_line = content_match ? content_match[1] : "Pytanie o: #{topic}?"

      answers_attributes = []
      answer_pattern = /\{"content":\s*"([^"]+)",\s*"correct":\s*(true|false)\}/
      content.scan(answer_pattern) do |content, correct|
        answers_attributes << {
          "content" => content,
          "correct" => correct == "true"
        }
      end

      if answers_attributes.empty?
        return create_fallback_question(topic, "multiple_choice")
      end

      while answers_attributes.size < 4
        answers_attributes << {
          "content" => "Odpowiedź #{('A'.ord + answers_attributes.size).chr}",
          "correct" => false
        }
      end

      unless answers_attributes.any? { |a| a["correct"] }
        answers_attributes[0]["correct"] = true
      end

      {
        "content" => question_line,
        "question_type" => "multiple_choice",
        "answers_attributes" => answers_attributes
      }

    when "open_ended"
      content_match = content.match(/"content":\s*"([^"]+)"/)
      question_line = content_match ? content_match[1] : "Wyjaśnij: #{topic}?"

      max_score_match = content.match(/"max_score":\s*(\d+)/)
      max_score = max_score_match ? max_score_match[1].to_i : 5

      {
        "content" => question_line,
        "question_type" => "open_ended",
        "max_score" => max_score
      }
    end
  end

  private

  def clean_json_content(content)
    cleaned = content.gsub(/```json\s*/, "").gsub(/\s*```/, "")
    cleaned.strip
  end
end
