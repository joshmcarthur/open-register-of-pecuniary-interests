


class WikimediaImageService
  BASE_URL = "https://en.wikipedia.org/w/api.php"

  def initialize(entity_name)
    @entity_name = entity_name
  end

  def fetch_profile_image
    # First, search for the Wikipedia page
    page_title = find_wikipedia_page
    return nil unless page_title

    # Then get the main image from that page
    image_data = get_page_main_image(page_title)
    return nil unless image_data

    # Download and return the image with metadata
    download_image_with_metadata(image_data[:url], page_title, image_data[:filename])
  end

  private

  def find_wikipedia_page
    search_params = {
      action: "query",
      list: "search",
      srsearch: @entity_name,
      srlimit: 1,
      format: "json"
    }

    response = make_request(search_params)
    return nil unless response&.dig("query", "search")&.any?

    response["query"]["search"].first["title"]
  end

  def get_page_main_image(page_title)
    image_params = {
      action: "query",
      titles: page_title,
      prop: "pageimages",
      piprop: "original",
      format: "json"
    }

    response = make_request(image_params)
    pages = response&.dig("query", "pages")
    return nil unless pages

    # Get the first (and usually only) page result
    page_data = pages.values.first
    original_image = page_data&.dig("original")
    return nil unless original_image

    {
      url: original_image["source"],
      filename: original_image["source"].split("/").last
    }
  end

  def download_image_with_metadata(image_url, wikipedia_page_title, original_filename)
    return nil unless image_url

    begin
      uri = URI(image_url)
      response = Net::HTTP.get_response(uri)

      return nil unless response.is_a?(Net::HTTPSuccess)

      # Create metadata hash
      metadata = {
        source: "wikimedia",
        wikipedia_page: wikipedia_page_title,
        wikipedia_url: "https://en.wikipedia.org/wiki/#{URI.encode_www_form_component(wikipedia_page_title)}",
        wikimedia_url: image_url,
        original_filename: original_filename,
        fetched_at: Time.current.iso8601,
        entity_name: @entity_name
      }

      {
        io: StringIO.new(response.body),
        filename: original_filename,
        content_type: response["content-type"] || "image/jpeg",
        metadata: metadata
      }
    rescue => e
      Rails.logger.error "Failed to download image from #{image_url}: #{e.message}"
      nil
    end
  end

  def make_request(params)
    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue => e
    Rails.logger.error "Wikimedia API request failed: #{e.message}"
    nil
  end
end
