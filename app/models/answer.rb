class Answer < ApplicationRecord
  belongs_to :question

  validates :content, presence: true
  validates :correct, inclusion: { in: [ true, false ] }
end
