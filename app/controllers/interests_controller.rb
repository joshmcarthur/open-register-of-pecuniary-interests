class InterestsController < ApplicationController
  def index
    # Set cache headers based on whether this is a search or browse
    if params[:q].present?
      # Search results can be cached for shorter periods
      set_short_cache_headers(15.minutes)
    else
      # Browse/filter results can be cached longer since data is read-only
      set_long_cache_headers
    end

    @filter = InterestsFilter.new(filter_params)

    if @filter.query.present?
      # Perform a search on the filtered relation
      search_service = InterestSearch.new(@filter.query, @filter.relation, { limit: 100 })
      search_results = search_service.search

      @interests = search_results[:results] || [] # Already sorted
      @total_count = @interests.length
      @search_types_used = search_results[:search_types_used] || []
      @search_breakdown = search_results[:breakdown] || {}
      @is_search_mode = true
    else
      # Use regular filter for browsing
      @interests = @filter.results
      @total_count = @filter.total_count
      @is_search_mode = false
    end

    render
  end

  private

  def filter_params
    params.permit(:jurisdiction, :party, :interest_category, :source, :page, :q)
  end

  def cache_key_for_current_data
    # Include filter parameters in cache key for proper cache invalidation
    filter_key = filter_params.to_h.sort.to_h.to_s
    "interests-#{action_name}-#{Digest::MD5.hexdigest(filter_key)}"
  end
end
