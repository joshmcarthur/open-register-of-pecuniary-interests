class ComparisonController < ApplicationController
  before_action :set_long_cache_headers, only: [ :index ]

  def index
    @comparison_stats = ComparisonStats.new
    @stats = @comparison_stats.overview_stats
    @party_stats = @comparison_stats.party_stats
    @category_stats = @comparison_stats.category_stats
    @individual_stats = @comparison_stats.individual_stats
  end

  private

  def cache_key_for_current_data
    # Use a static cache key since comparison data doesn't change
    "comparison-stats-#{last_modified_time.to_i}"
  end
end
