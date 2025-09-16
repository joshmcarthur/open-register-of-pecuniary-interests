namespace :import do
  desc "Import political entities and interests from JSONL file"
  task :json, [ :file ] => :environment do |t, args|
    file_path = Rails.root.join(args[:file] || ENV["JSONL_FILE"])

    unless File.exist?(file_path)
      puts "Error: File #{file_path} not found"
      exit 1
    end

    puts "Starting import from #{file_path}..."

    # Create or find the source
    source = Source.find_or_create_by(name: "2025 Register of Pecuniary and Other Specified Interests") do |s|
      s.year = 2025
      s.description = "Register of Pecuniary and Other Specified Interests for 2025"
    end

    # Create or find the jurisdiction (assuming this is for New Zealand Parliament)
    jurisdiction = Jurisdiction.find_or_create_by(name: "New Zealand Parliament") do |j|
      j.jurisdiction_type = "parliament"
      j.description = "New Zealand Parliament"
    end

    # Get all interest categories for quick lookup
    interest_categories = InterestCategory.all.index_by(&:key)

    imported_entities = 0
    imported_jurisdictions = 0
    imported_interests = 0
    skipped_entities = 0
    skipped_jurisdictions = 0
    skipped_interests = 0

    # Read and parse the JSONL file
    File.foreach(file_path) do |line|
      next if line.strip.empty?

      begin
        # Parse the JSON line
        data = JSON.parse(line.strip)

        # Skip if it's an array (the file starts with [)
        next if data.is_a?(Array)

        # Extract political entity information
        entity_name = data["name"]
        party = data["party"]
        electorate = data["electorate"]

        next unless entity_name.present?

        # Create or find political entity
        political_entity = PoliticalEntity.find_or_create_by(name: entity_name)

        if political_entity.persisted? && political_entity.previously_new_record?
          imported_entities += 1
        else
          skipped_entities += 1
        end

        # Create or find political entity jurisdiction
        role = "Member of Parliament"
        affiliation = party.present? ? party : nil

        political_entity_jurisdiction = PoliticalEntityJurisdiction.find_or_create_by(
          political_entity: political_entity,
          jurisdiction: jurisdiction
        ) do |pej|
          pej.role = role
          pej.electorate = electorate
          pej.affiliation = affiliation
        end

        if political_entity_jurisdiction.persisted? && political_entity_jurisdiction.previously_new_record?
          imported_jurisdictions += 1
        else
          skipped_jurisdictions += 1
        end

        # Process interests from sections
        sections = data["sections"] || {}

        sections.each do |section_key, section_data|
          interest_category = interest_categories[section_key]

          unless interest_category
            puts "Warning: Interest category '#{section_key}' not found, skipping..."
            next
          end

          items = section_data["items"] || []

          items.each do |item_description|
            next if item_description.blank?

            # Create interest record
            interest = Interest.find_or_create_by(
              description: item_description,
              political_entity_jurisdiction: political_entity_jurisdiction,
              interest_category: interest_category,
              source_page_numbers: data["source_page_numbers"],
              source: source
            )

            if interest.persisted? && interest.previously_new_record?
              imported_interests += 1
            else
              skipped_interests += 1
            end
          end
        end

      rescue JSON::ParserError => e
        puts "Error parsing JSON line: #{e.message}"
        puts "Line: #{line[0..100]}..."
        next
      rescue => e
        puts "Error processing line: #{e.message}"
        puts "Line: #{line[0..100]}..."
        next
      end
    end

    puts "\nImport completed!"
    puts "Political Entities: #{imported_entities} imported, #{skipped_entities} skipped"
    puts "Political Entity Jurisdictions: #{imported_jurisdictions} imported, #{skipped_jurisdictions} skipped"
    puts "Interests: #{imported_interests} imported, #{skipped_interests} skipped"
    puts "Total records processed: #{imported_entities + imported_jurisdictions + imported_interests}"
  end
end
