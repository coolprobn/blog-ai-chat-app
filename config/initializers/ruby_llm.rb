require "ruby_llm"

RubyLLM.configure do |config|
  # Set keys for the providers you need. Using environment variables is best practice.
  config.gemini_api_key =
    Rails.application.credentials.gemini[:api_key] || ENV["GEMINI_API_KEY"]
  # Add other keys like config.anthropic_api_key if needed
  # config.openai_api_key = ENV['OPENAI_API_KEY'] || Rails.application.credentials.dig(:openai_api_key)
  # config.default_model = "gpt-4.1-nano"

  config.default_model = "gemini-1.5-flash"
  config.default_embedding_model = "text-embedding-004"

  # Enable the new Rails-like API
  config.use_new_acts_as = true
end
