class MessagesController < ApplicationController
  def create
    @chat = Chat.find(params[:chat_id])
    question = params.require(:message).fetch(:content, "").to_s.strip

    if question.blank?
      redirect_to @chat, alert: "Message can't be blank" and return
    end

    system_prompt = <<~PROMPT
      You are an assistant that answers questions ONLY using the author's blog.

      You MUST:
      1. Call the BlogSearch tool before answering.
      2. Read ONLY the content between BLOG_CONTEXT_START and BLOG_CONTEXT_END.
      3. If the context equals "NO_RELEVANT_BLOG_CONTENT", respond with:
         "I couldn't find anything about this in the blog."

      Answer format (STRICT):
      Summary:
      - 2–3 bullet points summarizing the answer

      Answer:
      - Detailed explanation using only the blog content

      Links:
      - List URLs ONLY if they appear verbatim in the blog context
      - List should be in bullet points
      - If none exist, say "No relevant links found in the blog."

      You are FORBIDDEN from using external knowledge.
    PROMPT

    rag_chat = @chat.with_tool(BlogSearch).with_instructions(system_prompt)

    rag_chat.ask(question)

    persist_sources_from_tool!

    redirect_to @chat
  end

  private

  # Extract sources from the tool JSON and attach to the assistant message
  def persist_sources_from_tool!
    assistant = @chat.messages.where(role: "assistant").last
    tool_call = @chat.messages.where(role: "tool").last
    return unless assistant && tool_call

    payload =
      begin
        JSON.parse(tool_call.content)
      rescue StandardError
        {}
      end
    sources = payload["sources"] || []

    assistant.update_column(:sources, sources)
  end
end
