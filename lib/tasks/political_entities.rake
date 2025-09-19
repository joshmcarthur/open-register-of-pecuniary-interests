namespace :political_entities do
  desc "Fetch profile images for all political entities from Wikimedia"
  task :fetch_images, [ :jurisdiction_slug ] =>  :environment do |task, args|
    puts "Starting to fetch profile images for political entities..."

    jurisdiction_slug = args[:jurisdiction_slug]
    entities = PoliticalEntity.all

    if jurisdiction_slug.present?
      jurisdiction = Jurisdiction.find_by!(slug: jurisdiction_slug)
      entities = jurisdiction.political_entities
    end

    total = entities.count
    success_count = 0
    error_count = 0
    force = ENV["FORCE"] == "true"

    entities.each_with_index do |entity, index|
      puts "Processing #{index + 1}/#{total}: #{entity.name}"

      normalized_name = entity.name.gsub(/^Dr|Hon|Hon Dr|Rt Hon/, "").strip

      # Skip if already has an image
      if entity.profile_image.attached? && !force
        puts "  ✓ Already has profile image"
        next
      end

      begin
        # Add NZ to the name to increase the chances of finding an image that is correct
        service = WikimediaImageService.new(normalized_name + " NZ")
        image_data = service.fetch_profile_image

        if image_data
          entity.profile_image.attach(image_data)
          metadata = image_data[:metadata]
          puts "  ✓ Successfully attached profile image from #{metadata[:wikipedia_page]}"
          puts "    Wikipedia: #{metadata[:wikipedia_url]}"
          puts "    Image: #{metadata[:wikimedia_url]}"
          success_count += 1
        else
          puts "  ✗ No image found for #{entity.name}"
          error_count += 1
        end

        # Be respectful to the API - add a small delay
        sleep(1)
      rescue => e
        puts "  ✗ Error processing #{entity.name}: #{e.message}"
        error_count += 1
      end
    end

    puts "\n=== Summary ==="
    puts "Total entities: #{total}"
    puts "Successfully processed: #{success_count}"
    puts "Errors/No images found: #{error_count}"
    puts "Already had images: #{total - success_count - error_count}"
  end

  desc "Fetch profile image for a specific political entity"
  task :fetch_image, [ :entity_name ] => :environment do |task, args|
    entity_name = args[:entity_name]

    unless entity_name
      puts "Usage: rake political_entities:fetch_image['Entity Name']"
      exit 1
    end

    entity = PoliticalEntity.find_by(name: entity_name)
    unless entity
      puts "Political entity '#{entity_name}' not found"
      exit 1
    end

    puts "Fetching profile image for: #{entity.name}"
    service = WikimediaImageService.new(entity.name)
    image_data = service.fetch_profile_image

    if image_data
      entity.profile_image.attach(image_data)
      metadata = image_data[:metadata]
      puts "✓ Successfully attached profile image"
      puts "  Wikipedia page: #{metadata[:wikipedia_page]}"
      puts "  Wikipedia URL: #{metadata[:wikipedia_url]}"
      puts "  Image URL: #{metadata[:wikimedia_url]}"
    else
      puts "✗ No image found"
    end
  end

  desc "Show image metadata for all entities with images"
  task show_image_metadata: :environment do
    entities_with_images = PoliticalEntity.joins(:profile_image_attachment)

    puts "=== Image Metadata Report ==="
    puts "Total entities with images: #{entities_with_images.count}"
    puts

    entities_with_images.each do |entity|
      metadata = entity.profile_image_metadata
      puts "Entity: #{entity.name}"
      puts "  Source: #{metadata['source']}"
      puts "  Wikipedia Page: #{metadata['wikipedia_page']}"
      puts "  Fetched: #{metadata['fetched_at']}"
      puts "  Wikipedia URL: #{metadata['wikipedia_url']}"
      puts "  Image URL: #{metadata['wikimedia_url']}"
      puts
    end
  end
end
