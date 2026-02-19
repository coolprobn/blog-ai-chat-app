class SearchController < ApplicationController
  def create
    question = (params[:q] || params[:query]).to_s.strip

    if question.blank?
      @error_message = "Query is required"

      respond_to { |format| format.turbo_stream }
      return
    end

    chat = Chat.create!(chat_attrs)
    rag_chat = chat.with_tool(BlogSearch).with_instructions(system_prompt)
    rag_chat.ask(question)

    assistant = chat.messages.where(role: "assistant").last
    @sources = extract_sources(chat)
    raw_answer = assistant&.content.to_s
    @answer_html =
      Redcarpet::Markdown.new(
        Redcarpet::Render::HTML.new(filter_html: true),
        fenced_code_blocks: true,
        autolink: true
      ).render(raw_answer)

    respond_to { |format| format.turbo_stream }
  rescue StandardError => e
    Rails.logger.error(
      "[Search] #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    )
    @error_message = "Search failed. Please try again."
    respond_to { |format| format.turbo_stream }
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

      You MUST:
      1. Call the BlogSearch tool before answering.
      2. Read ONLY the content between BLOG_CONTEXT_START and BLOG_CONTEXT_END.
      3. If the context equals "NO_RELEVANT_BLOG_CONTENT", respond with: "I couldn't find anything about this in the blog."
      4. Always return the response in Markdown format.

      You are FORBIDDEN from using external knowledge.

      Response format:
      - Start with one or two short sentences summarizing the answer, then use <br /> to break the line.
      - Then give the detailed explanation. Use <br /> to break the line between each paragraph.
      - For lists: use Markdown bullets (- ) or numbers (1. 2. 3. ), with <br /> to break the line before the list and between list items if they are long.
      - Put code or commands in backticks. Use <br /> to break the line before and after code blocks if needed.
      - End with a link when relevant: "For more details, see [Post title](url)." Use only URLs from the context ([Source: ... | URL: ...]); never link to external sites.
      - Use two <br /> (a blank line) between sections so the response is easy to read. Do not output "Summary:" or "Answer:" - just the content.
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
