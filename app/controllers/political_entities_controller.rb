class PoliticalEntitiesController < ApplicationController
  def index
    @filter = PoliticalEntitiesFilter.new(filter_params)

    render
  end

  def show
    @political_entity = PoliticalEntity.find(params[:id])
    @active_tab = params[:tab] || "all"

    # Get all interest categories that have interests for this political entity
    @interest_categories = InterestCategory.joins(:interests)
                                          .joins("JOIN political_entity_jurisdictions ON interests.political_entity_jurisdiction_id = political_entity_jurisdictions.id")
                                          .where(political_entity_jurisdictions: { political_entity_id: @political_entity.id })
                                          .distinct
                                          .order(:label)

      # Get interests based on active tab
      @interests = @political_entity.interests.includes(:interest_category, :source, political_entity_jurisdiction: :jurisdiction)
                                   .order("interest_categories.label, interests.description")
      @interests = @interests.where(interest_categories: { key: @active_tab }) if @active_tab != "all"

    render
  end

  def export
    @political_entity = PoliticalEntity.find(params[:id])
    render csv: @political_entity.interests.to_csv
  end

  private

  def filter_params
    params.permit(:jurisdiction, :party, :interest_category)
  end
end
