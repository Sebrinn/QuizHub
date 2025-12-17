# app/helpers/open_answers_helper.rb
module OpenAnswersHelper
  def open_answer_status_badge(status)
    case status.to_sym
    when :pending then "warning"
    when :graded then "success"
    else "secondary"
    end
  end

  def open_answer_status_text(status)
    case status.to_sym
    when :pending then "Oczekuje na ocenę"
    when :graded then "Ocenione"
    else "Nieznany"
    end
  end
end
