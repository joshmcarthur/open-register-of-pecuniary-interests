class InterestsFilter
  attr_reader :jurisdiction_filter, :party_filter, :interest_category_filter, :interests, :jurisdictions, :parties, :interest_categories

  def initialize(params = {})
    @jurisdiction_filter = params[:jurisdiction]
    @party_filter = params[:party]
    @interest_category_filter = params[:interest_category]
    @source_filter = params[:source]

    @interests = build_filtered_interests
    @jurisdictions = load_jurisdictions
    @parties = load_parties
    @sources = load_sources
    @interest_categories = load_interest_categories
  end

  def filtered_count
    @interests.count
  end

  def has_active_filters?
    active_filters.any?
  end

  def active_filters
    filters = []
    filters << { type: :jurisdiction, value: @jurisdiction_filter, label: jurisdiction_label } if @jurisdiction_filter.present?
    filters << { type: :party, value: @party_filter, label: @party_filter } if @party_filter.present?
    filters << { type: :interest_category, value: @interest_category_filter, label: interest_category_label } if @interest_category_filter.present?
    filters << { type: :source, value: @source_filter, label: source_label } if @source_filter.present?
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

  def build_filtered_interests
    interests = Interest.includes(:interest_category, :source, political_entity_jurisdiction: [ :political_entity, :jurisdiction ])
                       .joins(political_entity_jurisdiction: [ :political_entity, :jurisdiction ])

    interests = apply_jurisdiction_filter(interests) if @jurisdiction_filter.present?
    interests = apply_party_filter(interests) if @party_filter.present?
    interests = apply_interest_category_filter(interests) if @interest_category_filter.present?
    interests = apply_source_filter(interests) if @source_filter.present?
    interests.distinct.order("interest_categories.label, interests.description")
  end

  def apply_jurisdiction_filter(interests)
    interests.where(jurisdictions: { slug: @jurisdiction_filter })
  end

  def apply_party_filter(interests)
    interests.where(political_entity_jurisdictions: { affiliation: @party_filter })
  end

  def apply_interest_category_filter(interests)
    interests.where(interest_categories: { key: @interest_category_filter })
  end

  def apply_source_filter(interests)
    interests.where(source_id: @source_filter)
  end

  def load_jurisdictions
    Jurisdiction.order(:name)
  end

  def load_sources
    Source.order(:name)
  end

  def load_parties
    PoliticalEntityJurisdiction.distinct.pluck(:affiliation).compact.sort
  end

  def load_interest_categories
    InterestCategory.order(:label)
  end

  def jurisdiction_label
    @jurisdictions.find_by(slug: @jurisdiction_filter)&.name if @jurisdiction_filter.present?
  end

  def interest_category_label
    @interest_categories.find_by(key: @interest_category_filter)&.label if @interest_category_filter.present?
  end

  def source_label
    @sources.find_by(id: @source_filter)&.name if @source_filter.present?
  end

  def build_url(params)
    Rails.application.routes.url_helpers.interests_path(params.compact)
  end
end
