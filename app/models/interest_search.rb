class InterestSearch
  SEARCH_TYPES = {
    like: 1,      # Highest priority - exact matches
    fts5: 2,       # Medium priority - full-text search
    vector: 3      # Lowest priority - semantic similarity
  }.freeze

  def initialize(query, base_relation = Interest.all, options = {})
    @query = query.to_s.strip
    @base_relation = base_relation
    @options = options
    @limit = options[:limit] || 50
  end

  def search
    return empty_results if @query.blank?

    results = []

    # Layer 1: LIKE search (highest priority)
    like_results = search_like
    results.concat(like_results.map { |interest| annotate_interest(interest, :like, SEARCH_TYPES[:like]) })

    # Layer 2: FTS5 search (medium priority) - only if we need more results
    if results.length < @limit
      fts5_results = search_fts5
      # Filter out results we already have from LIKE
      existing_ids = results.map(&:id)
      new_fts5_results = fts5_results.reject { |interest| existing_ids.include?(interest.id) }
      results.concat(new_fts5_results.map { |interest| annotate_interest(interest, :fts5, SEARCH_TYPES[:fts5]) })
    end

    # Layer 3: Vector search (lowest priority) - only if we still need more results
    if results.length < @limit
      vector_results = search_vector
      # Filter out results we already have
      existing_ids = results.map(&:id)
      new_vector_results = vector_results.reject { |interest| existing_ids.include?(interest.id) }
      results.concat(new_vector_results.map { |interest| annotate_interest(interest, :vector, SEARCH_TYPES[:vector]) })
    end

    # Sort by priority (lower number = higher priority), then by relevance score
    sorted_results = results.sort_by { |interest| [ interest.search_priority, -interest.search_relevance_score ] }.first(@limit)

    # Return structured results with metadata
    {
      results: sorted_results,
      total_count: sorted_results.length,
      search_types_used: sorted_results.map(&:search_type).uniq,
      query: @query,
      breakdown: {
        like_count: sorted_results.count { |interest| interest.search_type == :like },
        fts5_count: sorted_results.count { |interest| interest.search_type == :fts5 },
        vector_count: sorted_results.count { |interest| interest.search_type == :vector }
      }
    }
  end

  private

  def empty_results
    {
      results: [],
      total_count: 0,
      search_types_used: [],
      query: @query,
      breakdown: {
        like_count: 0,
        fts5_count: 0,
        vector_count: 0
      }
    }
  end

  def search_like
    # LIKE search across multiple fields
    search_conditions = [
      "interests.description LIKE ?",
      "political_entities.name LIKE ?",
      "jurisdictions.name LIKE ?",
      "interest_categories.label LIKE ?"
    ].join(" OR ")

    search_term = "%#{@query}%"
    @base_relation.includes(:political_entity, :jurisdiction, :interest_category)
                  .where(search_conditions, *([ search_term ] * 4))
  end


  def search_fts5
    @base_relation.search(@query)
  end


  def search_vector
    # Generate embedding for the search query
    query_embedding = EmbeddingService.generate_embedding(@query)
    return [] unless query_embedding

    @base_relation.where.not(embedding: nil).nearest_neighbors(:embedding, query_embedding, distance: :cosine).limit(20)
  end


  def annotate_interest(interest, search_type, priority)
    # Add search metadata to the interest object
    relevance_score = calculate_relevance_score(interest, search_type)
    interest.define_singleton_method(:search_type) { search_type }
    interest.define_singleton_method(:search_priority) { priority }
    interest.define_singleton_method(:search_relevance_score) { relevance_score }
    interest
  end

  def calculate_relevance_score(interest, search_type)
    case search_type
    when :like
      calculate_like_relevance(interest)
    when :fts5
      interest.rank || 0.5
    when :vector
      1.0 - interest.neighbor_distance # Convert distance to similarity score
    else
      0.0
    end
  end

  def calculate_like_relevance(interest)
    # Simple relevance scoring for LIKE matches on interests
    score = 0.0
    score += 1.0 if interest.description&.downcase&.include?(@query.downcase)
    score += 0.8 if interest.political_entity&.name&.downcase&.include?(@query.downcase)
    score += 0.6 if interest.jurisdiction&.name&.downcase&.include?(@query.downcase)
    score += 0.4 if interest.interest_category&.label&.downcase&.include?(@query.downcase)
    score
  end
end
