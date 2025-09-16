class InterestsController < ApplicationController
  def index
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
end
