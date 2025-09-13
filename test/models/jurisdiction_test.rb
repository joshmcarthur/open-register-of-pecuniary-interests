require "test_helper"

class JurisdictionTest < ActiveSupport::TestCase
  def setup
    @jurisdiction = jurisdictions(:nz_parliament)
  end

  test "should be valid" do
    assert @jurisdiction.valid?
  end

  test "name should be present" do
    @jurisdiction.name = nil
    assert_not @jurisdiction.valid?
    assert_includes @jurisdiction.errors[:name], "can't be blank"
  end

  test "name should be unique" do
    duplicate_jurisdiction = @jurisdiction.dup
    duplicate_jurisdiction.jurisdiction_type = "local_council"
    assert_not duplicate_jurisdiction.valid?
    assert_includes duplicate_jurisdiction.errors[:name], "has already been taken"
  end

  test "jurisdiction_type should be present" do
    @jurisdiction.jurisdiction_type = nil
    assert_not @jurisdiction.valid?
    assert_includes @jurisdiction.errors[:jurisdiction_type], "can't be blank"
  end

  test "should accept valid jurisdiction types" do
    valid_types = %w[parliament regional_council local_council]
    valid_types.each do |type|
      @jurisdiction.jurisdiction_type = type
      assert @jurisdiction.valid?, "#{type} should be valid"
    end
  end

  test "should reject invalid jurisdiction types" do
    assert_raises ArgumentError, /'invalid_type' is not a valid jurisdiction type/ do
      @jurisdiction.jurisdiction_type = "invalid_type"
    end
  end

  test "should have many political entity jurisdictions" do
    assert_respond_to @jurisdiction, :political_entity_jurisdictions
    assert @jurisdiction.political_entity_jurisdictions.any?
  end

  test "should have many political entities through political entity jurisdictions" do
    assert_respond_to @jurisdiction, :political_entities
    assert @jurisdiction.political_entities.any?
  end

  test "should have many interests through political entity jurisdictions" do
    assert_respond_to @jurisdiction, :interests
  end

  test "description should be optional" do
    @jurisdiction.description = nil
    assert @jurisdiction.valid?
  end
end
