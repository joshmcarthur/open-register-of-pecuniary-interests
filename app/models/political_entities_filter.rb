class PoliticalEntitiesFilter
  attr_reader :jurisdiction_filter, :party_filter, :interest_category_filter, :jurisdiction_type_filter, :political_entities, :jurisdictions, :parties, :interest_categories, :jurisdiction_types

  def initialize(params = {})
    @jurisdiction_filter = params[:jurisdiction]
    @party_filter = params[:party]
    @interest_category_filter = params[:interest_category]
    @jurisdiction_type_filter = Array(params[:jurisdiction_type]).reject(&:blank?)

    @political_entities = build_filtered_entities
    @jurisdictions = load_jurisdictions
    @parties = load_parties
    @interest_categories = load_interest_categories
    @jurisdiction_types = load_jurisdiction_types
  end

  def filtered_count
    @political_entities.count
  end

  def has_active_filters?
    @jurisdiction_filter.present? || @party_filter.present? || @interest_category_filter.present? || @jurisdiction_type_filter.any?
  end

  def active_filters
    filters = []
    filters << { type: :jurisdiction, value: @jurisdiction_filter, label: jurisdiction_label } if @jurisdiction_filter.present?
    filters << { type: :party, value: @party_filter, label: @party_filter } if @party_filter.present?
    filters << { type: :interest_category, value: @interest_category_filter, label: interest_category_label } if @interest_category_filter.present?
    filters << { type: :jurisdiction_type, value: @jurisdiction_type_filter, label: jurisdiction_type_label } if @jurisdiction_type_filter.any?
    filters
  end

  def clear_filter_url(filter_type)
    case filter_type
    when :jurisdiction
      build_url(party: @party_filter, interest_category: @interest_category_filter, jurisdiction_type: @jurisdiction_type_filter)
    when :party
      build_url(jurisdiction: @jurisdiction_filter, interest_category: @interest_category_filter, jurisdiction_type: @jurisdiction_type_filter)
    when :interest_category
      build_url(jurisdiction: @jurisdiction_filter, party: @party_filter, jurisdiction_type: @jurisdiction_type_filter)
    when :jurisdiction_type
      build_url(jurisdiction: @jurisdiction_filter, party: @party_filter, interest_category: @interest_category_filter)
    end
  end

  private

  def build_filtered_entities
    entities = PoliticalEntity.includes(:jurisdictions, :interests, political_entity_jurisdictions: :jurisdiction)
                             .joins(:political_entity_jurisdictions)

    entities = apply_jurisdiction_filter(entities) if @jurisdiction_filter.present?
    entities = apply_party_filter(entities) if @party_filter.present?
    entities = apply_interest_category_filter(entities) if @interest_category_filter.present?
    entities = apply_jurisdiction_type_filter(entities) if @jurisdiction_type_filter.any?

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

  def apply_jurisdiction_type_filter(entities)
    entities.where(jurisdictions: { jurisdiction_type: @jurisdiction_type_filter })
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

  def load_jurisdiction_types
    Jurisdiction.distinct.pluck(:jurisdiction_type).compact.sort
  end

  def jurisdiction_label
    @jurisdictions.find { |j| j.slug == @jurisdiction_filter }&.name if @jurisdiction_filter.present?
  end

  def interest_category_label
    @interest_categories.find { |c| c.key == @interest_category_filter }&.label if @interest_category_filter.present?
  end

  def jurisdiction_type_label
    if @jurisdiction_type_filter.any?
      @jurisdiction_type_filter.map { |type| type.humanize }.join(", ")
    end
  end

  def build_url(params)
    Rails.application.routes.url_helpers.political_entities_path(params.compact)
  end
end
