class SearchController < ApplicationController
  skip_before_action :verify_authenticity_token, if: -> { request.format.json? }

  def create
    question = (params[:q] || params[:query]).to_s.strip
    if question.blank?
      return render json: { error: "Query is required" }, status: :unprocessable_entity
    end

    chat = Chat.create!(chat_attrs)
    rag_chat = chat.with_tool(BlogSearch).with_instructions(system_prompt)
    rag_chat.ask(question)

    assistant = chat.messages.where(role: "assistant").last
    sources = extract_sources(chat)
    raw_answer = assistant&.content.to_s
    answer_html = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(filter_html: true), fenced_code_blocks: true, autolink: true).render(raw_answer)

    render json: {
      answer: raw_answer,
      answer_html: answer_html,
      sources: sources
    }
  rescue StandardError => e
    Rails.logger.error("[Search] #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    render json: { error: "Search failed. Please try again.", answer: "" }, status: :internal_server_error
  end

  private

  def chat_attrs
    {
      model: "qwen2.5:7b-instruct",
      provider: :ollama,
      assume_model_exists: true
    }
  end

  def system_prompt
    <<~PROMPT
      You are an assistant that answers questions ONLY using the author's blog.
      You MUST call the BlogSearch tool before answering.
      Read ONLY the content between BLOG_CONTEXT_START and BLOG_CONTEXT_END.
      If the context equals "NO_RELEVANT_BLOG_CONTENT", respond with: "I couldn't find anything about this in the blog."
      Answer clearly. List URLs ONLY if they appear verbatim in the blog context. You are FORBIDDEN from using external knowledge.
    PROMPT
  end

  def extract_sources(chat)
    tool_msg = chat.messages.where(role: "tool").last
    return [] unless tool_msg

    payload = JSON.parse(tool_msg.content)
    payload["sources"] || []
  rescue StandardError
    []
  end
end
