class MessagesController < ApplicationController
  def create
    @chat = Chat.find(params[:chat_id])
    content = params.require(:message).fetch(:content, "").to_s

    if content.blank?
      redirect_to @chat, alert: "Message can't be blank" and return
    end

    rag_chat =
      @chat.with_tool(BlogSearch).with_instructions(
        "You are an assistant answering questions about my personal blog. " \
          "Before answering, call the BlogSearch tool with the user's question " \
          "to fetch relevant blog content, then answer using only that content. " \
          "If the tool result does not contain enough information, say you don't know " \
          "based on the blog content you have."
      )

    rag_chat.ask(content)

    redirect_to @chat
  end
end
