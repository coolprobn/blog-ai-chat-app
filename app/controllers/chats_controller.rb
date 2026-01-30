class ChatsController < ApplicationController
  def index
    @chats = Chat.order(created_at: :desc)
  end

  def show
    @chat = Chat.find(params[:id])
    @message = @chat.messages.build
  end

  def create
    @chat =
      Chat.create!(
        model: "qwen2.5:7b-instruct",
        provider: :ollama,
        assume_model_exists: true
      )

    redirect_to @chat
  end
end
