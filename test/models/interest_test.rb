require "test_helper"

class InterestTest < ActiveSupport::TestCase
  def setup
    @interest = interests(:john_smith_company)
  end

  test "should be valid" do
    assert @interest.valid?
  end

  test "description should be present" do
    @interest.description = nil
    assert_not @interest.valid?
    assert_includes @interest.errors[:description], "can't be blank"
  end

  test "description should not be empty" do
    @interest.description = ""
    assert_not @interest.valid?
    assert_includes @interest.errors[:description], "can't be blank"
  end

  test "should belong to interest category" do
    assert_respond_to @interest, :interest_category
    assert_equal InterestCategory.find_by!(key: "company_directorships_and_controlling_interests"), @interest.interest_category
  end

  test "should belong to political entity jurisdiction" do
    assert_respond_to @interest, :political_entity_jurisdiction
    assert_equal political_entity_jurisdictions(:john_smith_parliament), @interest.political_entity_jurisdiction
  end

  test "should belong to source" do
    assert_respond_to @interest, :source
    assert_equal sources(:register_2025), @interest.source
  end

  test "should have one political entity through political entity jurisdiction" do
    assert_respond_to @interest, :political_entity
    assert_equal political_entities(:john_smith), @interest.political_entity
  end

  test "should have one jurisdiction through political entity jurisdiction" do
    assert_respond_to @interest, :jurisdiction
    assert_equal jurisdictions(:nz_parliament), @interest.jurisdiction
  end

  test "source_page_numbers should be serialized as JSON" do
    @interest.source_page_numbers = [ 1, 2, 3 ]
    assert @interest.valid?
    assert_equal [ 1, 2, 3 ], @interest.source_page_numbers
  end

  test "source_page_numbers should default to empty array" do
    new_interest = Interest.new(
      description: "Test interest",
      interest_category: InterestCategory.find_by!(key: "company_directorships_and_controlling_interests"),
      political_entity_jurisdiction: political_entity_jurisdictions(:john_smith_parliament),
      source: sources(:register_2025)
    )
    assert_equal [], new_interest.source_page_numbers
  end

  test "metadata should accept JSON" do
    @interest.metadata = { "key" => "value", "number" => 123 }
    assert @interest.valid?
    assert_equal({ "key" => "value", "number" => 123 }, @interest.metadata)
  end

  test "metadata should default to empty hash" do
    new_interest = Interest.new(
      description: "Test interest",
      interest_category: InterestCategory.find_by!(key: "company_directorships_and_controlling_interests"),
      political_entity_jurisdiction: political_entity_jurisdictions(:john_smith_parliament),
      source: sources(:register_2025)
    )
    assert_equal({}, new_interest.metadata)
  end
end
