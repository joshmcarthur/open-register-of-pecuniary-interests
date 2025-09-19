class PoliticalEntitiesController < ApplicationController
  before_action :set_long_cache_headers, only: [ :index, :show, :export ]
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
    export = PoliticalEntityInterestsExport.new(@political_entity)

    send_data export.to_csv,
              filename: export.filename,
              type: "text/csv",
              disposition: "attachment"
  end

  private

  def filter_params
    params.permit(:jurisdiction, :party, :interest_category, jurisdiction_type: [])
  end

  def cache_key_for_current_data
    case action_name
    when "index"
      filter_key = filter_params.to_h.sort.to_h.to_s
      "political-entities-index-#{Digest::MD5.hexdigest(filter_key)}"
    when "show"
      "political-entity-#{params[:id]}-#{params[:tab] || 'all'}"
    else
      super
    end
  end
end
