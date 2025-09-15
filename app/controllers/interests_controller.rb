class InterestsController < ApplicationController
  def index
    @filter = InterestsFilter.new(filter_params)
    render
  end

  private

  def filter_params
    params.permit(:jurisdiction, :party, :interest_category, :source, :page)
  end
end
