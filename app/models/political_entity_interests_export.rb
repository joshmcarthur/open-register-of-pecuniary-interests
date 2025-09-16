require "csv"

class PoliticalEntityInterestsExport
  def initialize(political_entity)
    @political_entity = political_entity
  end

  def to_csv
    CSV.generate do |csv|
      csv << headers
      interests.each { |interest| csv << row_data(interest) }
    end
  end

  def filename
    "#{@political_entity.name.parameterize}-interests-#{Date.current.strftime('%Y-%m-%d')}.csv"
  end

  private

  attr_reader :political_entity

  def headers
    [
      "Political Entity Name",
      "Jurisdiction",
      "Role",
      "Electorate",
      "Affiliation",
      "Interest Category",
      "Interest Description",
      "Source Name",
      "Source Year",
      "Source URL",
      "Source Page Numbers"
    ]
  end

  def interests
    @interests ||= political_entity.interests.includes(
      :interest_category,
      :source,
      political_entity_jurisdiction: [ :jurisdiction, :political_entity ]
    ).order("interest_categories.label, interests.description")
  end

  def row_data(interest)
    pej = interest.political_entity_jurisdiction

    [
      political_entity.name,
      pej.jurisdiction.name,
      pej.role,
      pej.electorate || "",
      pej.affiliation || "",
      interest.interest_category.label,
      interest.description,
      interest.source.name,
      interest.source.year,
      extract_source_url(interest.source),
      format_page_numbers(interest.source_page_numbers)
    ]
  end

  def extract_source_url(source)
    return "" unless source.metadata.present?

    source.metadata["url"] ||
    source.metadata["source_url"] ||
    source.metadata["link"] || ""
  end

  def format_page_numbers(page_numbers)
    return "" if page_numbers.blank? || page_numbers == "[]"

    if page_numbers.is_a?(Array)
      page_numbers.join(", ")
    else
      page_numbers.to_s
    end
  end
end

