class MessagesController < ApplicationController
  def create
    @chat = Chat.find(params[:chat_id])
    question = params.require(:message).fetch(:content, "").to_s

    if question.blank?
      redirect_to @chat, alert: "Message can't be blank" and return
    end

    prompt = <<~TEXT.strip
      You are an assistant answering questions about my personal blog.
      Before answering the question, call the BlogSearch tool with the user's question to fetch relevant blog context and sources, then answer using only that content.
      If the tool result does not contain enough information, say you don't know based on the blog content you have.
      If the tool result contains enough information, cite sources as [1], [2], etc. when you use content from a numbered block.
    TEXT

    rag_chat = @chat.with_tool(BlogSearch).with_instructions(prompt)
    rag_chat.ask(question)

    # default order for messages is "asc" so last message is the most recent
    last_message = @chat.messages.where(role: "assistant").last

    # TODO: find some way to get the sources from the tool call
    # Is there a way to manually do the tool call without multiple calls to the same tool? Right now we can only retrieve sources if we break execute and search and tool calls execute while we call search again to get sources. That wouldn't be ideal.
    result = BlogSearch.new.search(question)

    if last_message && result[:sources].any?
      last_message&.update_column(:sources, result[:sources])
    end

    redirect_to @chat
  end
end
