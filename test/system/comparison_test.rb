require "application_system_test_case"

class ComparisonTest < ApplicationSystemTestCase
  test "viewing comparison page structure" do
    visit comparison_index_path

    # Check main heading
    assert_text "Political Interest Comparison"
    assert_text "Comprehensive analysis of declared financial interests across political parties and categories"

    # Check overview statistics are displayed
    assert_text "Total Entities"
    assert_text "Total Interests"
    assert_text "Average per Entity"
    assert_text "Maximum"
    assert_text "Minimum"

    # Check chart sections
    assert_text "Interests by Party"
    assert_text "Interest Categories"

    # Check tables
    assert_text "Top 10 by Interest Count"
    assert_text "Party Statistics"
  end

  test "overview statistics display correct values" do
    visit comparison_index_path

    # Based on fixtures, we have:
    # - 4 political entities (john_smith, jane_doe, bob_wilson, alice_brown)
    # - 5 interests total
    # - Average should be 5/4 = 1.25

    # Find the stats values
    within(".grid.grid-cols-1.sm\\:grid-cols-2") do
      # Total entities should be 4
      entities_stat = find(".stat", text: "Total Entities")
      within(entities_stat) do
        assert_text "4"
      end

      # Total interests should be 5
      interests_stat = find(".stat", text: "Total Interests")
      within(interests_stat) do
        assert_text "5"
      end

      # Average should be 1.25
      average_stat = find(".stat", text: "Average per Entity")
      within(average_stat) do
        assert_text "1.25"
      end
    end
  end

  test "party statistics table displays fixture data" do
    visit comparison_index_path

    # Check that party statistics section exists
    assert_text "Party Statistics"

    # Look for the table within the party statistics card
    within(".card", text: "Party Statistics") do
      # Should show Labour Party (2 members: John Smith, Alice Brown)
      assert_text "Labour Party"

      # Should show Green Party (1 member: Jane Doe)
      assert_text "Green Party"

      # Should show National Party (1 member: Bob Wilson)
      assert_text "National Party"

      # Check table headers
      assert_text "Party"
      assert_text "Members"
      assert_text "Total Interests"
      assert_text "Average per Member"
    end
  end

  test "top individuals table displays fixture data" do
    visit comparison_index_path

    # Check that top individuals section exists
    assert_text "Top 10 by Interest Count"

    # Look for the table within the top individuals card
    within(".card", text: "Top 10 by Interest Count") do
      # Should show our political entities
      assert_text "John Smith" # Has 2 interests
      assert_text "Jane Doe"   # Has 1 interest
      assert_text "Bob Wilson" # Has 1 interest
      assert_text "Alice Brown" # Has 1 interest

      # Check table headers
      assert_text "Rank"
      assert_text "Name"
      assert_text "Interest Count"
      assert_text "Actions"

      # Check that John Smith is ranked #1 (has most interests)
      first_row = find("tbody tr:first-child")
      within(first_row) do
        assert_text "1"
        assert_text "John Smith"
        assert_text "2" # Interest count
      end
    end
  end

  test "chart elements are present" do
    visit comparison_index_path

    # Check that chart canvases exist
    assert_selector "canvas[data-controller='chartjs']", count: 2

    # Check party chart
    party_chart = find("canvas[data-chartjs-type-value='bar']")
    assert party_chart.present?

    # Check category chart (doughnut)
    category_chart = find("canvas[data-chartjs-type-value='doughnut']")
    assert category_chart.present?
  end

  test "navigation from comparison to individual entities" do
    visit comparison_index_path

    # Click on "View Details" for John Smith
    within(".card", text: "Top 10 by Interest Count") do
      john_row = find("tr", text: "John Smith")
      within(john_row) do
        click_link "View Details"
      end
    end

    # Should navigate to a political entity page (path may include slug)
    assert_current_path %r{/political-entities/[^/]+}
    assert_text "John Smith"
  end

  test "navigating to comparison from home page" do
    visit root_path

    # Click the Compare Parties link
    click_link "Compare"

    assert_current_path comparison_index_path
    assert_text "Political Interest Comparison"
  end
end
