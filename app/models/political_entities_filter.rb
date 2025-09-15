class PoliticalEntitiesFilter
  attr_reader :jurisdiction_filter, :party_filter, :interest_category_filter, :political_entities, :jurisdictions, :parties, :interest_categories

  def initialize(params = {})
    @jurisdiction_filter = params[:jurisdiction]
    @party_filter = params[:party]
    @interest_category_filter = params[:interest_category]

    @political_entities = build_filtered_entities
    @jurisdictions = load_jurisdictions
    @parties = load_parties
    @interest_categories = load_interest_categories
  end

  def filtered_count
    @political_entities.count
  end

  def has_active_filters?
    @jurisdiction_filter.present? || @party_filter.present? || @interest_category_filter.present?
  end

  def active_filters
    filters = []
    filters << { type: :jurisdiction, value: @jurisdiction_filter, label: jurisdiction_label } if @jurisdiction_filter.present?
    filters << { type: :party, value: @party_filter, label: @party_filter } if @party_filter.present?
    filters << { type: :interest_category, value: @interest_category_filter, label: interest_category_label } if @interest_category_filter.present?
    filters
  end

  def clear_filter_url(filter_type)
    case filter_type
    when :jurisdiction
      build_url(party: @party_filter, interest_category: @interest_category_filter)
    when :party
      build_url(jurisdiction: @jurisdiction_filter, interest_category: @interest_category_filter)
    when :interest_category
      build_url(jurisdiction: @jurisdiction_filter, party: @party_filter)
    end
  end

  private

  def build_filtered_entities
    entities = PoliticalEntity.includes(:jurisdictions, :interests, political_entity_jurisdictions: :jurisdiction)
                             .joins(:political_entity_jurisdictions)

    entities = apply_jurisdiction_filter(entities) if @jurisdiction_filter.present?
    entities = apply_party_filter(entities) if @party_filter.present?
    entities = apply_interest_category_filter(entities) if @interest_category_filter.present?

    entities.distinct.order(:name)
  end

  def apply_jurisdiction_filter(entities)
    entities.where(jurisdictions: { slug: @jurisdiction_filter })
  end

  def apply_party_filter(entities)
    entities.where(political_entity_jurisdictions: { affiliation: @party_filter })
  end

  def apply_interest_category_filter(entities)
    entities.joins(interests: :interest_category)
            .where(interest_categories: { key: @interest_category_filter })
  end

  def load_jurisdictions
    Jurisdiction.order(:name)
  end

  def load_parties
    PoliticalEntityJurisdiction.distinct.pluck(:affiliation).compact.sort
  end

  def load_interest_categories
    InterestCategory.order(:label)
  end

  def jurisdiction_label
    @jurisdictions.find { |j| j.slug == @jurisdiction_filter }&.name if @jurisdiction_filter.present?
  end

  def interest_category_label
    @interest_categories.find { |c| c.key == @interest_category_filter }&.label if @interest_category_filter.present?
  end

  def build_url(params)
    Rails.application.routes.url_helpers.political_entities_path(params.compact)
  end
end
