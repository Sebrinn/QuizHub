class TemporaryAiQuestion < ApplicationRecord
  validates :session_id, :quiz_id, presence: true

  # Czyść stare rekordy (np. starsze niż 1 godzina)
  def self.clean_old_records
    where("created_at < ?", 1.hour.ago).delete_all
  end
end
