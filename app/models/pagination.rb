


class Pagination
  attr_reader :current_page, :total_pages, :total_count, :per_page

  def initialize(current_page:, total_count:, per_page: 12)
    @current_page = [ current_page.to_i, 1 ].max
    @total_count = total_count
    @per_page = per_page
    @total_pages = (@total_count.to_f / @per_page).ceil
  end

  def next_page
    @current_page + 1 if has_next_page?
  end

  def previous_page
    @current_page - 1 if has_previous_page?
  end

  def has_next_page?
    @current_page < @total_pages
  end

  def has_previous_page?
    @current_page > 1
  end

  def page_numbers
    start_page = [ @current_page - 2, 1 ].max
    end_page = [ @current_page + 2, @total_pages ].min

    pages = []

    # Add first page if not in range
    if start_page > 1
      pages << { number: 1, current: false }
      pages << { number: nil, ellipsis: true } if start_page > 2
    end

    # Add page range
    (start_page..end_page).each do |page|
      pages << { number: page, current: page == @current_page }
    end

    # Add last page if not in range
    if end_page < @total_pages
      pages << { number: nil, ellipsis: true } if end_page < @total_pages - 1
      pages << { number: @total_pages, current: false }
    end

    pages
  end

  def visible?
    @total_pages > 1
  end
end
