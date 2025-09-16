class ComparisonController < ApplicationController
  def index
    @comparison_stats = ComparisonStats.new
    @stats = @comparison_stats.overview_stats
    @party_stats = @comparison_stats.party_stats
    @category_stats = @comparison_stats.category_stats
    @individual_stats = @comparison_stats.individual_stats
  end
end
