class InterestsController < ApplicationController
  def index
    @filter = InterestsFilter.new(filter_params)

    # Delegate to the filter object
    @interests = @filter.interests
    @jurisdictions = @filter.jurisdictions
    @parties = @filter.parties
    @interest_categories = @filter.interest_categories
    @jurisdiction_filter = @filter.jurisdiction_filter
    @party_filter = @filter.party_filter
    @interest_category_filter = @filter.interest_category_filter

    render
  end

  private

  def filter_params
    params.permit(:jurisdiction, :party, :interest_category, :source)
  end
end
