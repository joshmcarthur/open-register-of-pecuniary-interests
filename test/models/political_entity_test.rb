require "test_helper"

class PoliticalEntityTest < ActiveSupport::TestCase
  def setup
    @political_entity = political_entities(:john_smith)
  end

  test "should be valid" do
    assert @political_entity.valid?
  end

  test "name should be present" do
    @political_entity.name = nil
    assert_not @political_entity.valid?
    assert_includes @political_entity.errors[:name], "can't be blank"
  end

  test "name should be unique" do
    duplicate_entity = @political_entity.dup
    assert_not duplicate_entity.valid?
    assert_includes duplicate_entity.errors[:name], "has already been taken"
  end

  test "should have many political entity jurisdictions" do
    assert_respond_to @political_entity, :political_entity_jurisdictions
    assert @political_entity.political_entity_jurisdictions.any?
  end

  test "should have many jurisdictions through political entity jurisdictions" do
    assert_respond_to @political_entity, :jurisdictions
    assert @political_entity.jurisdictions.any?
  end

  test "should have many interests through political entity jurisdictions" do
    assert_respond_to @political_entity, :interests
  end

  test "description should be optional" do
    @political_entity.description = nil
    assert @political_entity.valid?
  end

  test "should be able to have multiple jurisdictions" do
    # Create a new jurisdiction and assign it to the political entity
    new_jurisdiction = jurisdictions(:auckland_council)
    new_association = PoliticalEntityJurisdiction.new(
      political_entity: @political_entity,
      jurisdiction: new_jurisdiction,
      role: "councillor"
    )
    assert new_association.valid?
  end
end
