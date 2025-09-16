class ComparisonStats
  def initialize
    @total_interests = Interest.count
    @total_entities = PoliticalEntity.joins(:political_entity_jurisdictions).distinct.count
    @total_categories = InterestCategory.count
  end

  def overview_stats
    {
      total_interests: @total_interests,
      total_entities: @total_entities,
      total_categories: @total_categories,
      average_interests_per_entity: calculate_average_interests_per_entity,
      max_interests: max_interests_count,
      min_interests: min_interests_count
    }
  end

  def party_stats
    @party_stats ||= calculate_party_stats
  end

  def category_stats
    @category_stats ||= calculate_category_stats
  end

  def individual_stats
    @individual_stats ||= calculate_individual_stats
  end

  def party_chart_data
    {
      labels: party_stats.map { |party| party[:name] },
      datasets: [ {
        label: "Total Interests",
        data: party_stats.map { |party| party[:interest_count] },
        backgroundColor: generate_colors(party_stats.length, 0.7),
        borderColor: generate_colors(party_stats.length, 1.0),
        borderWidth: 2
      } ]
    }
  end

  def party_chart_options
    {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: false
        },
        title: {
          display: true,
          text: "Interests by Political Party"
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          ticks: {
            precision: 0
          }
        }
      }
    }
  end

  def category_chart_data
    {
      labels: category_stats.map { |category| category[:label] },
      datasets: [ {
        data: category_stats.map { |category| category[:count] },
        backgroundColor: generate_colors(category_stats.length, 0.7),
        borderColor: generate_colors(category_stats.length, 1.0),
        borderWidth: 2
      } ]
    }
  end

  def category_chart_options
    {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: "bottom",
          labels: {
            padding: 20,
            usePointStyle: true
          }
        },
        title: {
          display: true,
          text: "Distribution of Interest Categories"
        }
      }
    }
  end

  private

  def calculate_average_interests_per_entity
    @total_entities > 0 ? (@total_interests.to_f / @total_entities).round(2) : 0
  end

  def calculate_party_stats
    party_data = PoliticalEntityJurisdiction
      .joins(:interests, :political_entity)
      .where.not(affiliation: [ nil, "" ])
      .group(:affiliation)
      .select("affiliation, COUNT(DISTINCT political_entities.id) as entity_count, COUNT(interests.id) as interest_count")
      .order("interest_count DESC")

    party_data.map do |party|
      {
        name: party.affiliation,
        entity_count: party.entity_count,
        interest_count: party.interest_count,
        average_interests: party.entity_count > 0 ? (party.interest_count.to_f / party.entity_count).round(2) : 0
      }
    end
  end

  def calculate_category_stats
    category_data = Interest
      .joins(:interest_category)
      .group("interest_categories.key", "interest_categories.label")
      .select("interest_categories.key, interest_categories.label, COUNT(*) as count")
      .order("count DESC")

    category_data.map do |category|
      {
        key: category.key,
        label: category.label,
        count: category.count,
        percentage: @total_interests > 0 ? ((category.count.to_f / @total_interests) * 100).round(1) : 0
      }
    end
  end

  def calculate_individual_stats
    top_entities = PoliticalEntity
      .joins(political_entity_jurisdictions: :interests)
      .group("political_entities.id", "political_entities.name")
      .select("political_entities.id, political_entities.name, COUNT(interests.id) as interest_count")
      .order("interest_count DESC")
      .limit(10)

    top_entities.map do |entity|
      {
        id: entity.id,
        name: entity.name,
        interest_count: entity.interest_count
      }
    end
  end

  def max_interests_count
    @max_interests_count ||= PoliticalEntity
      .joins(political_entity_jurisdictions: :interests)
      .group("political_entities.id")
      .select("COUNT(interests.id) as interest_count")
      .order("interest_count DESC")
      .limit(1)
      .first&.interest_count || 0
  end

  def min_interests_count
    @min_interests_count ||= PoliticalEntity
      .joins(political_entity_jurisdictions: :interests)
      .group("political_entities.id")
      .select("COUNT(interests.id) as interest_count")
      .order("interest_count ASC")
      .limit(1)
      .first&.interest_count || 0
  end

  def generate_colors(count, alpha = 1.0)
    colors = [
      "#3B82F6", # blue
      "#EF4444", # red
      "#10B981", # green
      "#F59E0B", # yellow
      "#8B5CF6", # purple
      "#06B6D4", # cyan
      "#84CC16", # lime
      "#F97316", # orange
      "#EC4899", # pink
      "#6B7280"  # gray
    ]

    (0...count).map do |i|
      color = colors[i % colors.length]
      alpha < 1.0 ? color + (alpha * 255).round.to_s(16).rjust(2, "0") : color
    end
  end
end
