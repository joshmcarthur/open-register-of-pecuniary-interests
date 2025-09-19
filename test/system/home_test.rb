require "application_system_test_case"

class HomeTest < ApplicationSystemTestCase
  test "visiting the home page" do
    visit root_path

    # Check main heading and content
    assert_text "Open Register of Pecuniary Interests"
    assert_text "See what companies, properties, and investments your elected officials have declared."

    # Check search form is present
    assert_selector "form[role='search']"
    assert_selector "input[type='search'][name='q']"
    assert_selector "input[type='submit'][value='Search']"

    # Check navigation cards
    assert_text "Browse Parliament"
    assert_text "Explore Interests"
    assert_text "Compare Parties"
    assert_text "Browse Councils"

    # Check stats section displays
    assert_text "Current MPs"
    assert_text "Current Councillors"
    assert_text "Declared Interests"
    assert_text "Latest Data"

    # Check data source information
    assert_text "About This Data"
    assert_text "New Zealand elected officials are legally required"
    assert_text "contact@open-register-of-pecuniary-interests.joshmcarthur.com"
  end

  test "searching from home page" do
    visit root_path

    # Perform a search
    fill_in "q", with: "John Smith"
    click_button "Search"

    # Should redirect to interests page with search results (may include query parameters)
    assert_current_path interests_path, ignore_query: true
    assert_text "Search results for \"John Smith\""
  end

  test "navigation from home page cards" do
    visit root_path

    # Test Browse Parliament link
    click_link "Browse", match: :first
    assert_current_path political_entities_path(jurisdiction: "new-zealand-parliament")

    visit root_path

    # Test Explore Interests link
    click_link "Explore"
    assert_current_path interests_path

    visit root_path

    # Test Compare Parties link
    click_link "Compare"
    assert_current_path comparison_index_path

    visit root_path

    # Test Browse Councils link
    click_link "Browse", href: political_entities_path(jurisdiction: "greater-wellington-regional-council")
    assert_current_path political_entities_path(jurisdiction: "greater-wellington-regional-council")
  end

  test "responsive design elements" do
    visit root_path

    # Check that key responsive classes are present
    assert_selector ".container"
    assert_selector ".grid.grid-cols-1.md\\:grid-cols-2.lg\\:grid-cols-4"
    assert_selector ".stats.stats-vertical.sm\\:stats-horizontal"
  end
end
