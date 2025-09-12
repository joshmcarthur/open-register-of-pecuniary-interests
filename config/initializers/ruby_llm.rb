RubyLLM.configure do |config|
  config.use_new_acts_as = true
  config.gemini_api_key = ENV.fetch("GEMINI_API_KEY")
  config.default_model = "gemini-2.5-flash"
end
