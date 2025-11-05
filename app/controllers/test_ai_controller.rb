class TestAiController < ApplicationController
  skip_before_action :verify_authenticity_token

  def test_generation
    generator = PollinationsAiGenerator.new
    questions = generator.generate_questions(params[:topic] || "programowanie", count: 2)

    render json: {
      topic: params[:topic],
      questions: questions
    }
  end
end
