class EmbeddingService
  def self.generate_embedding(text, model: ENV.fetch("DEFAULT_EMBEDDING_MODEL", "gemini-embedding-001"))
    return nil if text.blank?

    embedding = RubyLLM.embed(text, model: model).vectors
    # Convert to binary format for storage
    embedding.pack("F*")
  rescue => e
    Rails.logger.error "Failed to generate embedding for text: #{e.message}"
    nil
  end
end
