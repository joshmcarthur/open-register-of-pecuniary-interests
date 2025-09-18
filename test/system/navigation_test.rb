require "application_system_test_case"

class NavigationTest < ApplicationSystemTestCase
  test "main navigation flow between pages" do
    # Start at home page
    visit root_path
    assert_text "Open Register of Pecuniary Interests"

    # Navigate to interests
    click_link "Explore"
    assert_current_path interests_path
    assert_text "Interests"

    # Navigate to a political entity (click first instance if multiple)
    click_link "John Smith", match: :first
    assert_current_path political_entity_path(political_entities(:john_smith))
    assert_text "John Smith"

    # Navigate to comparison via home
    visit root_path
    click_link "Compare"
    assert_current_path comparison_index_path
    assert_text "Political Interest Comparison"
  end

  test "search navigation flow" do
    # Start at home page
    visit root_path

    # Perform search from home
    fill_in "q", with: "Smith"
    click_button "Search"

    # Should be on interests page with search results (may include query parameters)
    assert_current_path interests_path, ignore_query: true
    assert_text "Search results for \"Smith\""

    # Click on a result to view political entity (specify first match to avoid ambiguity)
    click_link "John Smith", match: :first
    assert_current_path political_entity_path(political_entities(:john_smith))
    assert_text "John Smith"
  end

  test "political entities navigation flow" do
    # Start from political entities index
    visit political_entities_path

    # Should show all political entities
    assert_text "John Smith"
    assert_text "Jane Doe"
    assert_text "Bob Wilson"
    assert_text "Alice Brown"

    # Click on a specific entity
    click_link "John Smith"
    assert_current_path political_entity_path(political_entities(:john_smith))

    # Should show entity details and interests
    assert_text "John Smith"
    assert_text "Director of Smith Holdings Ltd"
    assert_text "Residential property at 123 Queen Street"
  end

  test "comparison to individual entity navigation" do
    # Start at comparison page
    visit comparison_index_path

    # Should have comparison content
    assert_text "Political Interest Comparison"

    # If there are "View Details" links, test navigation
    if page.has_link?("View Details")
      click_link "View Details", match: :first
      # Should navigate to a political entity page
      assert_current_path %r{/political-entities/[^/]+}
      assert_selector "h1, h2, h3"
    else
      # Just verify the comparison page loads properly
      assert_text "Total Entities"
      assert_text "Total Interests"
    end
  end

  test "interests filtering and back to browsing" do
    visit interests_path

    # Apply a filter
    select "Labour", from: "party"
    click_button "Apply Filters"

    # Should show filtered results
    assert_selector ".badge", text: /Party.*Labour/

    # Clear filters to return to browsing
    click_link "Clear Filters"

    # Should show all interests again
    assert_no_selector ".badge", text: /Party/
    assert_text "Director of Smith Holdings Ltd"
    assert_text "Part-time consultant for Environmental Solutions Ltd"
  end

  test "direct URL access to all main pages" do
    # Test that direct URL access works for all main pages
    visit root_path
    assert_text "Open Register of Pecuniary Interests"

    visit interests_path
    assert_text "Interests"

    visit political_entities_path
    assert_text "John Smith"

    visit comparison_index_path
    assert_text "Political Interest Comparison"

    # Test direct access to political entity
    visit political_entity_path(political_entities(:john_smith))
    assert_text "John Smith"
    assert_text "Member of Parliament for Auckland Central"
  end

  test "browser back and forward navigation" do
    # Test browser back button behavior
    visit root_path
    click_link "Explore"
    assert_current_path interests_path

    # Use browser back
    page.go_back
    assert_current_path root_path

    # Use browser forward
    page.go_forward
    assert_current_path interests_path
  end
end
