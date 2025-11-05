# app/helpers/quizzes_helper.rb
module QuizzesHelper
  def quiz_status_text(status)
    case status
    when :draft then "Szkic"
    when :upcoming then "Nadchodzący"
    when :ongoing then "Aktywny"
    when :finished then "Zakończony"
    else status.to_s
    end
  end

  def status_badge_color(status)
    case status
    when :draft then "secondary"
    when :upcoming then "warning"
    when :ongoing then "success"
    when :finished then "info"
    else "secondary"
    end
  end

  def result_percentage_color(score, total)
    percentage = (score.to_f / total) * 100
    if percentage >= 80
      "success"
    elsif percentage >= 50
      "warning"
    else
      "danger"
    end
  end

  def result_status_badge(status)
    case status.to_sym
    when :active then "success"
    when :inactive then "secondary"
    when :retaken then "info"
    else "light"
    end
  end

  def result_status_text(status)
    case status.to_sym
    when :active then "Aktywne"
    when :inactive then "Dezaktywowane"
    when :retaken then "Zastąpione"
    else status
    end
  end
end
