module ApplicationHelper
  def filter_badge_class(filter_type)
    case filter_type
    when :jurisdiction
      "badge-primary"
    when :party
      "badge-secondary"
    when :interest_category
      "badge-accent"
    when :source
      "badge-warning"
    else
      "badge-neutral"
    end
  end

  def political_party_badge(party, **kwargs)
    case party
    when "National"
      image_tag("party-logos/nz-national.png", **kwargs.reverse_merge(alt: "National Party"))
    when "Labour"
      image_tag("party-logos/nz-labour.svg", **kwargs.reverse_merge(alt: "Labour Party"))
    when "Green"
      image_tag("party-logos/nz-green.svg", **kwargs.reverse_merge(alt: "Green Party"))
    when "NZ First"
      image_tag("party-logos/nz-new-zealand-first.png", **kwargs.reverse_merge(alt: "NZ First Party"))
    when "ACT"
      image_tag("party-logos/nz-act.svg", **kwargs.reverse_merge(alt: "ACT Party"))
    when "Te Pāti Māori"
      image_tag("party-logos/nz-te-pati-maori.svg", **kwargs.reverse_merge(alt: "Te Pāti Māori"))
    end
  end
end
