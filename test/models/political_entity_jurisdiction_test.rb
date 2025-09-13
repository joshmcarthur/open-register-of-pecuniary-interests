require "test_helper"

class PoliticalEntityJurisdictionTest < ActiveSupport::TestCase
  def setup
    @political_entity_jurisdiction = political_entity_jurisdictions(:john_smith_parliament)
  end

  test "should be valid" do
    assert @political_entity_jurisdiction.valid?
  end

  test "should belong to political entity" do
    assert_respond_to @political_entity_jurisdiction, :political_entity
    assert_equal political_entities(:john_smith), @political_entity_jurisdiction.political_entity
  end

  test "should belong to jurisdiction" do
    assert_respond_to @political_entity_jurisdiction, :jurisdiction
    assert_equal jurisdictions(:nz_parliament), @political_entity_jurisdiction.jurisdiction
  end

  test "role should be present" do
    @political_entity_jurisdiction.role = nil
    assert_not @political_entity_jurisdiction.valid?
    assert_includes @political_entity_jurisdiction.errors[:role], "can't be blank"
  end

  test "electorate should be optional" do
    @political_entity_jurisdiction.electorate = nil
    assert @political_entity_jurisdiction.valid?
  end

  test "affiliation should be optional" do
    @political_entity_jurisdiction.affiliation = nil
    assert @political_entity_jurisdiction.valid?
  end

  test "start_date should be optional" do
    @political_entity_jurisdiction.start_date = nil
    assert @political_entity_jurisdiction.valid?
  end

  test "end_date should be optional" do
    @political_entity_jurisdiction.end_date = nil
    assert @political_entity_jurisdiction.valid?
  end

  test "should have many interests" do
    assert_respond_to @political_entity_jurisdiction, :interests
  end

  test "should be able to create valid political entity jurisdiction" do
    new_association = PoliticalEntityJurisdiction.new(
      political_entity: political_entities(:jane_doe),
      jurisdiction: jurisdictions(:auckland_council),
      role: "councillor"
    )
    assert new_association.valid?
  end

  test "should accept date formats for start_date and end_date" do
    @political_entity_jurisdiction.start_date = Date.new(2023, 10, 14)
    @political_entity_jurisdiction.end_date = Date.new(2026, 10, 14)
    assert @political_entity_jurisdiction.valid?
  end
end
