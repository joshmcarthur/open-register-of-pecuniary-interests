class HomepageStats
  include Singleton

  attr_reader :mps_count, :council_members_count, :declared_interests_count, :latest_data_year

  def initialize
    @mps_count = calculate_mps_count
    @council_members_count = calculate_council_members_count
    @declared_interests_count = calculate_declared_interests_count
    @latest_data_year = calculate_latest_data_year
  end

  def self.instance
    super
  end

  private

  def calculate_mps_count
    # Count political entities who have at least one parliamentary jurisdiction
    PoliticalEntity.joins(:jurisdictions)
                   .where(jurisdictions: { jurisdiction_type: "parliament" })
                   .distinct
                   .count
  end

  def calculate_council_members_count
    # Count political entities who have at least one non-parliamentary jurisdiction
    PoliticalEntity.joins(:jurisdictions)
                   .where.not(jurisdictions: { jurisdiction_type: "parliament" })
                   .distinct
                   .count
  end

  def calculate_declared_interests_count
    Interest.count
  end

  def calculate_latest_data_year
    # Get the latest year from sources
    Source.maximum(:year) || Date.current.year
  end
end
