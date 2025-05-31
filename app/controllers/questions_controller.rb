class QuestionsController < ApplicationController
  def new
  end

  def create
    question = params[:question]

    question_embedding = RubyLLM.embed(question)

    matches =
      ArticleChunk.nearest_neighbors(
        :embedding,
        question_embedding.vectors,
        distance: "cosine"
      ).limit(5)
    context = matches.map(&:content).join("\n\n")

    prompt = <<~TEXT
      Use the following blog content to answer the question.

      Context:
      #{context}
      
      Question: #{question}
    TEXT

    @answer = RubyLLM.chat.ask(prompt).content
    @answer_markdown =
      Redcarpet::Markdown.new(
        Redcarpet::Render::HTML,
        fenced_code_blocks: true
      ).render(@answer)

    render turbo_stream:
             turbo_stream.replace(
               "answer",
               partial: "questions/answer",
               locals: {
                 answer: @answer_markdown
               }
             )
  end
end
