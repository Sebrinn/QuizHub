# app/services/openrouter_generator.rb
class OpenrouterAiGenerator
  API_URL = "https://openrouter.ai/api/v1/chat/completions".freeze

  def initialize(api_key = Rails.application.credentials.openrouter[:api_key])
    @api_key = api_key
  end


  def generate_single_question(topic, question_number = 1)
    puts "TEST: Generating question #{question_number} for: #{topic}"

    response = call_openrouter_api(topic, question_number)

    if response&.success?
      body = response.body.force_encoding("UTF-8")
      puts "API Success for question #{question_number}! Response length: #{body.length}"

      question_data = parse_ai_response(body, topic)
      question_data || create_fallback_question(topic)
    else
      puts "API Error for question #{question_number}"
      create_fallback_question(topic)
    end
  end

  def generate_questions(prompt, count: 1)
    puts "TEST: Generating #{count} questions for: #{prompt}"

    questions = []

    count.times do |i|
      puts "Generating question #{i + 1}/#{count}"
      question = generate_single_question(prompt, i + 1)
      questions << question

      # Małe opóźnienie między requestami żeby nie przeciążyć API
      sleep(1) if count > 1 && i < count - 1
    end

    questions
  end

  def call_openrouter_api(topic, question_number = 1)
    headers = {
      "Authorization" => "Bearer #{@api_key}",
      "Content-Type" => "application/json",
      "HTTP-Referer" => "http://localhost:3000",
      "X-Title" => "QuizHub"
    }

    system_prompt = <<~PROMPT
      Stwórz pytanie wielokrotnego wyboru na temat: #{topic}

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

    body = {
      model: "deepseek/deepseek-chat-v3.1:free",
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

  def create_fallback_question(topic)
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


  private


  def parse_ai_response(response_body, topic)
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

      if valid_question_structure?(question_data)
        puts "VALID QUESTION STRUCTURE FOUND"
        question_data
      else
        puts "INVALID QUESTION STRUCTURE"
        nil
      end

    rescue JSON::ParserError => e
      puts "JSON Parse Error: #{e.message}"
      extract_json_from_text(ai_content, topic)
    rescue => e
      puts "General Parse Error: #{e.message}"
      nil
    end
  end

  def clean_json_content(content)
    cleaned = content.gsub(/```json\s*/, "").gsub(/\s*```/, "")
    cleaned.strip
  end

  def extract_json_from_text(content, topic)
    puts "Extracting JSON from text..."
    json_match = content.match(/\{.*\}/m)

    if json_match
      begin
        json_string = json_match[0]
        puts "EXTRACTED JSON:"
        puts json_string

        question_data = JSON.parse(json_string)

        if valid_question_structure?(question_data)
          puts "VALID QUESTION STRUCTURE FROM EXTRACTED JSON"
          return question_data
        end
      rescue JSON::ParserError => e
        puts "Extracted JSON parse error: #{e.message}"
      end
    end

    puts "Using structured fallback parsing..."
    structured_fallback(content, topic)
  end

  def structured_fallback(content, topic)
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
      return create_fallback_question(topic)
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
  end

  def valid_question_structure?(data)
    return false unless data.is_a?(Hash)
    return false unless data["content"].is_a?(String) && data["content"].include?("?")
    return false unless data["question_type"] == "multiple_choice"
    return false unless data["answers_attributes"].is_a?(Array)
    return false unless data["answers_attributes"].size >= 4

    correct_answers = data["answers_attributes"].count { |a| a["correct"] == true }
    return false unless correct_answers >= 1

    data["answers_attributes"].all? { |a| a["content"].is_a?(String) && a["content"].length > 0 }
  end
end
