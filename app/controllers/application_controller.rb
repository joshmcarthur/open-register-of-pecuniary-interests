class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Set default cache headers for all actions
  # Since this is a read-only database, we can cache aggressively
  before_action :set_default_cache_headers

  private

  # Set default cache control for 1 hour
  # Individual controllers can override this for specific needs
  def set_default_cache_headers
    expires_in 1.hour, public: true
  end

  def set_long_cache_headers(duration = 1.day)
    expires_in duration, public: true
    # Add ETag and Last-Modified headers for better cache validation
    fresh_when(etag: cache_key_for_current_data, last_modified: last_modified_time)
  end

  def set_short_cache_headers(duration = 5.minutes)
    expires_in duration, public: true
  end

  def set_no_cache_headers
    expires_now
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
  end

  # Helper method to generate cache keys based on current data
  def cache_key_for_current_data
    # This can be overridden in individual controllers for more specific cache keys
    "#{controller_name}-#{action_name}-#{params}"
  end

  # Helper method to get last modified time
  def last_modified_time
    # This can be overridden in individual controllers
    # For now, use a fixed time since data is read-only
    Time.zone.parse(ENV.fetch("DATA_LAST_MODIFIED_AT", "2025-01-01 00:00:00 UTC"))
  end
end
