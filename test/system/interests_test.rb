require "application_system_test_case"

class InterestsTest < ApplicationSystemTestCase
  test "browsing interests index" do
    visit interests_path

    # Check page structure
    assert_text "Interests"
    assert_text "Browse and filter interests by jurisdiction, party affiliation, and interest categories."

    # Check search form
    assert_selector "form[role='search']"
    assert_selector "input[name='q']"

    # Check filters section
    assert_text "Filters"
    assert_selector "select[name='jurisdiction']"
    assert_selector "select[name='party']"
    assert_selector "select[name='interest_category']"

    # Check that interests are displayed (from fixtures)
    assert_text "Director of Smith Holdings Ltd"
    assert_text "Part-time consultant for Environmental Solutions Ltd"
    assert_text "Trustee of Wilson Family Trust"

    # Check interest cards have proper structure
    assert_selector ".card .card-body h3", text: "Director of Smith Holdings Ltd"
    assert_selector ".badge", text: "Company directorships and controlling interests"

    # Check political entity links
    assert_link "John Smith"
    assert_link "Jane Doe"
  end

  test "searching interests" do
    visit interests_path

    # Perform search
    fill_in "q", with: "Smith"
    click_button "Search"

    # Check search results
    assert_text "Search results for \"Smith\""
    assert_text "Director of Smith Holdings Ltd"

    # Should show John Smith's interests but not others
    assert_text "John Smith"
    assert_no_text "Jane Doe"

    # Check search breakdown if present
    assert_text "result"
  end

  test "filtering interests by jurisdiction" do
    visit interests_path

    # Apply jurisdiction filter
    select "NZ Parliament", from: "jurisdiction"
    click_button "Apply Filters"

    # Should show only parliament-related interests
    assert_text "Director of Smith Holdings Ltd" # John Smith - Parliament
    assert_text "Gift of artwork valued at $500" # Alice Brown - Parliament
    assert_no_text "Part-time consultant for Environmental Solutions Ltd" # Jane Doe - Wellington Council

    # Check active filter badge
    assert_selector ".badge", text: /Jurisdiction.*NZ Parliament/

    # Test clearing filter
    click_link "×"
    assert_no_selector ".badge", text: /Jurisdiction.*NZ Parliament/
  end

  test "filtering interests by party affiliation" do
    visit interests_path

    # Apply party filter
    select "Labour Party", from: "party"
    click_button "Apply Filters"

    # Should show only Labour Party interests
    assert_text "Director of Smith Holdings Ltd" # John Smith - Labour
    assert_text "Gift of artwork valued at $500" # Alice Brown - Labour
    assert_no_text "Part-time consultant for Environmental Solutions Ltd" # Jane Doe - Green Party
    assert_no_text "Trustee of Wilson Family Trust" # Bob Wilson - National Party

    # Check active filter badge
    assert_selector ".badge", text: /Party.*Labour Party/
  end

  test "filtering interests by category" do
    visit interests_path

    # Apply interest category filter
    select "Company directorships and controlling interests", from: "interest_category"
    click_button "Apply Filters"

    # Should show only company directorship interests
    assert_text "Director of Smith Holdings Ltd"
    assert_no_text "Part-time consultant for Environmental Solutions Ltd" # Employment category
    assert_no_text "Trustee of Wilson Family Trust" # Trusts category

    # Check active filter badge
    assert_selector ".badge", text: /Interest category.*Company directorships/
  end

  test "combining multiple filters" do
    visit interests_path

    # Apply multiple filters
    select "NZ Parliament", from: "jurisdiction"
    select "Labour Party", from: "party"
    click_button "Apply Filters"

    # Should show only Labour MPs' interests
    assert_text "Director of Smith Holdings Ltd" # John Smith - Labour MP
    assert_text "Gift of artwork valued at $500" # Alice Brown - Labour MP
    assert_no_text "Part-time consultant for Environmental Solutions Ltd" # Jane Doe - not Parliament
    assert_no_text "Trustee of Wilson Family Trust" # Bob Wilson - not Labour

    # Check multiple active filter badges
    assert_selector ".badge", text: /Jurisdiction.*NZ Parliament/
    assert_selector ".badge", text: /Party.*Labour Party/
  end

  test "clearing all filters" do
    visit interests_path

    # Apply some filters
    select "NZ Parliament", from: "jurisdiction"
    select "Labour Party", from: "party"
    click_button "Apply Filters"

    # Verify filters are active
    assert_selector ".badge", text: /Jurisdiction.*NZ Parliament/
    assert_selector ".badge", text: /Party.*Labour Party/

    # Clear all filters
    click_link "Clear Filters"

    # Should show all interests again and no filter badges
    assert_no_selector ".badge", text: /Jurisdiction/
    assert_no_selector ".badge", text: /Party/
    assert_text "Director of Smith Holdings Ltd"
    assert_text "Part-time consultant for Environmental Solutions Ltd"
    assert_text "Trustee of Wilson Family Trust"
  end

  test "interest card interactions" do
    visit interests_path

    # Test political entity link directly (more reliable than dropdown)
    click_link "John Smith", match: :first
    assert_current_path political_entity_path(political_entities(:john_smith))
    assert_text "John Smith"
  end

  test "no results state" do
    visit interests_path

    # Search for something that won't match
    fill_in "q", with: "nonexistent search term xyz123"
    click_button "Search"

    # Check no results message
    assert_text "No Interests Found"
    assert_text "No interests match your current filter criteria"
    assert_link "Clear All Filters"
    assert_link "Back to Search"
  end

  test "search with filters preserved" do
    visit interests_path

    # Apply a filter first
    select "Labour Party", from: "party"
    click_button "Apply Filters"

    # Then search
    fill_in "q", with: "Smith"
    click_button "Search"

    # Should maintain the party filter in search
    assert_text "Search results for \"Smith\""
    assert_selector ".badge", text: /Party.*Labour Party/

    # Hidden fields should preserve filters
    assert_selector "input[name='party'][type='hidden'][value='Labour Party']", visible: false
  end
end
