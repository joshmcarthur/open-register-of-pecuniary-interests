RubyLLM.configure do |config|
  config.use_new_acts_as = true
  config.request_timeout = 5.minutes
  config.gemini_api_key = ENV.fetch("GEMINI_API_KEY")
  config.anthropic_api_key = ENV.fetch("ANTHROPIC_API_KEY")
  config.default_model = ENV.fetch("DEFAULT_CHAT_MODEL", "gemini-2.5-flash")
end
