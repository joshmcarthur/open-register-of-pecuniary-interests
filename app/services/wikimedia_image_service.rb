


class WikimediaImageService
  BASE_URL = "https://en.wikipedia.org/w/api.php"

  def initialize(entity_name)
    @entity_name = entity_name
  end

  def fetch_profile_image
    # First, search for images directly on Wikimedia
    image_data = find_wikimedia_image
    return nil unless image_data

    # Optionally search for Wikipedia page if it exists
    wikipedia_page_title = find_wikipedia_page

    # Download and return the image with metadata
    download_image_with_metadata(
      image_data[:url],
      wikipedia_page_title,
      image_data[:filename],
      image_data[:title]
    )
  end

  private

  def find_wikimedia_image
    # Search for images using the search API
    search_params = {
      action: "query",
      list: "search",
      srsearch: "#{@entity_name} filetype:bitmap",
      srnamespace: 6, # File namespace
      srlimit: 1,
      format: "json"
    }

    response = make_request(search_params)
    return nil unless response&.dig("query", "search")&.any?

    # Get the first search result
    first_result = response["query"]["search"].first
    return nil unless first_result

    # Get the full image details
    get_image_details(first_result["title"])
  end

  def get_image_details(image_title)
    # Remove "File:" prefix if present
    clean_title = image_title.gsub(/^File:/, "")

    image_params = {
      action: "query",
      titles: image_title,
      prop: "imageinfo",
      iiprop: "url|size|mime",
      iiurlwidth: 512,
      format: "json"
    }

    response = make_request(image_params)
    pages = response&.dig("query", "pages")
    return nil unless pages

    # Get the first (and usually only) page result
    page_data = pages.values.first
    imageinfo = page_data&.dig("imageinfo")&.first
    return nil unless imageinfo

    {
      url: imageinfo["url"] || imageinfo["thumburl"],
      filename: clean_title,
      title: image_title
    }
  end

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

  def download_image_with_metadata(image_url, wikipedia_page_title, original_filename, image_title)
    return nil unless image_url

    begin
      uri = URI(image_url)
      response = Net::HTTP.get_response(uri)

      return nil unless response.is_a?(Net::HTTPSuccess)

      # Create metadata hash
      metadata = {
        source: "wikimedia",
        wikipedia_page: wikipedia_page_title,
        wikipedia_url: wikipedia_page_title ? "https://en.wikipedia.org/wiki/#{URI.encode_www_form_component(wikipedia_page_title)}" : nil,
        wikimedia_url: image_url,
        wikimedia_image_title: image_title,
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
