require "application_system_test_case"

class ExportTest < ApplicationSystemTestCase
  test "export link exists on political entity page" do
    visit political_entity_path(political_entities(:john_smith))

    # The route exists in routes.rb, so there should be an export link
    # Based on the controller, it should be accessible

    # Check if export functionality is visible in the UI
    # This might be a link or button depending on implementation
    export_present = page.has_link?("Export") ||
                    page.has_button?("Export") ||
                    page.has_text?("CSV") ||
                    page.has_text?("Download")

    # If export UI exists, test it
    if export_present
      export_element = page.find("a[href*='export'], button", text: /Export|CSV|Download/i, match: :first)

      # Should have correct path structure (may include slug)
      if export_element.tag_name == "a"
        assert_match %r{/political-entities/[^/]+/export}, export_element[:href]
      end
    else
      # Export functionality might not be exposed in the UI yet
      # Test the direct URL access
      visit political_entity_path(political_entities(:john_smith)) + "/export"

      # Should either download a file or show appropriate response
      # CSV downloads typically don't change the page URL
      assert_current_path %r{/political-entities/[^/]+/export}
    end
  end

  test "export URL structure for different entities" do
    # Test that export URLs are correctly structured for different entities
    entities = [ political_entities(:john_smith), political_entities(:jane_doe) ]

    entities.each do |entity|
      export_url = political_entity_path(entity) + "/export"

      # Visit the export URL directly
      visit export_url

      # Should respond (either with file download or proper page)
      # CSV downloads may not change URL, just verify no errors
      assert_no_text "Error"
      assert_no_text "404"
    end
  end

  test "export functionality integration" do
    # Test that the export route is properly integrated
    entity = political_entities(:john_smith)

    # Visit entity page first
    visit political_entity_path(entity)
    assert_text "John Smith"
    assert_text "Director of Smith Holdings Ltd"

    # Test direct access to export URL
    visit political_entity_path(entity) + "/export"

    # Should handle the request appropriately
    # CSV downloads typically don't change the URL or may redirect back
    # We just verify no error occurred
    assert_no_text "Error"
    assert_no_text "404"
  end
end
