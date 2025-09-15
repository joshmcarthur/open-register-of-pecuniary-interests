module ApplicationHelper
  def filter_badge_class(filter_type)
    case filter_type
    when :jurisdiction
      "badge-primary"
    when :party
      "badge-secondary"
    when :interest_category
      "badge-accent"
    else
      "badge-neutral"
    end
  end
end
