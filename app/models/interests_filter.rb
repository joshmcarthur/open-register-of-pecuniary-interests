class InterestsFilter
  PER_PAGE = 12 # Number of interests per page
  DEFAULT_ORDER = "interest_categories.label, interests.description"

  attr_reader :jurisdiction_filter,
              :party_filter,
              :interest_category_filter,
              :results,
              :relation,
              :jurisdictions,
              :parties,
              :interest_categories,
              :jurisdiction_types,
              :jurisdiction_type_filter,
              :pagination,
              :query,
              :source_filter,
              :total_count

  def initialize(params = {})
    @query = params[:q]&.strip
    @order = params[:order] || DEFAULT_ORDER
    @paginate = params.fetch(:paginate, true)
    @jurisdiction_filter = params[:jurisdiction]
    @party_filter = params[:party]
    @interest_category_filter = params[:interest_category]
    @jurisdiction_type_filter = Array(params[:jurisdiction_type]).reject(&:blank?)
    @source_filter = params[:source]
    @current_page = [ params[:page].to_i, 1 ].max

    # Calculate categorisations
    @jurisdictions = load_jurisdictions
    @parties = load_parties
    @sources = load_sources
    @interest_categories = load_interest_categories
    @jurisdiction_types = load_jurisdiction_types

    # Calculate overall relation, then paginate and order if required
    @relation = build_relation
    @results = @relation
    @total_count = @relation.distinct.count
    @results = @results.order(@order) if @order.present?
    @results = @results.limit(PER_PAGE).offset((@current_page - 1) * PER_PAGE) if @paginate
    @pagination = Pagination.new(
      current_page: @current_page,
      total_count: @total_count,
      per_page: PER_PAGE
    )
  end

  def filtered_count
    @total_count
  end

  def has_active_filters?
    active_filters.any? || @query.present?
  end

  def active_filters
    filters = []
    filters << { type: :query, value: @query, label: @query } if @query.present?
    filters << { type: :jurisdiction, value: @jurisdiction_filter, label: jurisdiction_label } if @jurisdiction_filter.present?
    filters << { type: :party, value: @party_filter, label: @party_filter } if @party_filter.present?
    filters << { type: :interest_category, value: @interest_category_filter, label: interest_category_label } if @interest_category_filter.present?
    filters << { type: :jurisdiction_type, value: @jurisdiction_type_filter, label: jurisdiction_type_label } if @jurisdiction_type_filter.any?
    filters << { type: :source, value: @source_filter, label: source_label } if @source_filter.present?
    filters
  end

  def clear_filter_url(filter_type)
    case filter_type
    when :query
      build_url(jurisdiction: @jurisdiction_filter, party: @party_filter, interest_category: @interest_category_filter, source: @source_filter)
    when :jurisdiction
      build_url(q: @query, party: @party_filter, interest_category: @interest_category_filter, source: @source_filter)
    when :party
      build_url(q: @query, jurisdiction: @jurisdiction_filter, interest_category: @interest_category_filter, source: @source_filter)
    when :interest_category
      build_url(q: @query, jurisdiction: @jurisdiction_filter, party: @party_filter, source: @source_filter)
    when :source
      build_url(q: @query, jurisdiction: @jurisdiction_filter, party: @party_filter, interest_category: @interest_category_filter)
    end
  end

  def pagination_params
    {
      q: @query,
      jurisdiction: @jurisdiction_filter,
      party: @party_filter,
      interest_category: @interest_category_filter,
      source: @source_filter
    }.compact
  end

  # Pagination helper methods
  def next_page_url
    return nil unless @pagination.has_next_page?
    build_url(pagination_params.merge(page: @pagination.next_page))
  end

  def previous_page_url
    return nil unless @pagination.has_previous_page?
    build_url(pagination_params.merge(page: @pagination.previous_page))
  end

  def page_url(page_number)
    build_url(pagination_params.merge(page: page_number))
  end

  def build_relation
    relation = Interest.includes(:interest_category, :source, political_entity_jurisdiction: [ :political_entity, :jurisdiction ])
                       .joins(political_entity_jurisdiction: [ :political_entity, :jurisdiction ])

    relation = apply_jurisdiction_filter(relation) if @jurisdiction_filter.present?
    relation = apply_party_filter(relation) if @party_filter.present?
    relation = apply_interest_category_filter(relation) if @interest_category_filter.present?
    relation = apply_source_filter(relation) if @source_filter.present?
    relation = apply_jurisdiction_type_filter(relation) if @jurisdiction_type_filter.any?

    relation
  end


  private

  def load_jurisdiction_types
    Jurisdiction.distinct.pluck(:jurisdiction_type).compact.sort
  end

  def apply_jurisdiction_type_filter(interests)
    interests.where(jurisdictions: { jurisdiction_type: @jurisdiction_type_filter })
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

  def jurisdiction_type_label
    if @jurisdiction_type_filter.any?
      @jurisdiction_type_filter.map { |type| type.humanize }.join(", ")
    end
  end

  def source_label
    @sources.find_by(id: @source_filter)&.name if @source_filter.present?
  end

  def build_url(params)
    Rails.application.routes.url_helpers.interests_path(params.compact)
  end
end
