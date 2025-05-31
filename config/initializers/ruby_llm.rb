require "ruby_llm"

RubyLLM.configure do |config|
  # Set keys for the providers you need. Using environment variables is best practice.
  config.gemini_api_key =
    Rails.application.credentials.gemini[:api_key] || ENV["GEMINI_API_KEY"]
  # Add other keys like config.anthropic_api_key if needed

  config.default_model = "gemini-1.5-flash"
  config.default_embedding_model = "text-embedding-004"
end
