require "test_helper"

class SourceTest < ActiveSupport::TestCase
  def setup
    @source = sources(:register_2025)
  end

  test "should be valid" do
    assert @source.valid?
  end

  test "name should be present" do
    @source.name = nil
    assert_not @source.valid?
    assert_includes @source.errors[:name], "can't be blank"
  end

  test "name should be unique" do
    duplicate_source = @source.dup
    duplicate_source.year = 2026
    assert_not duplicate_source.valid?
    assert_includes duplicate_source.errors[:name], "has already been taken"
  end

  test "year should be present" do
    @source.year = nil
    assert_not @source.valid?
    assert_includes @source.errors[:year], "can't be blank"
  end

  test "should have many interests" do
    assert_respond_to @source, :interests
    assert @source.interests.any?
  end

  test "should have many interest categories through interests" do
    assert_respond_to @source, :interest_categories
  end

  test "should have many political entities through interests" do
    assert_respond_to @source, :political_entities
  end

  test "should have many jurisdictions through interests" do
    assert_respond_to @source, :jurisdictions
  end

  test "should have one attached file" do
    assert_respond_to @source, :file
  end

  test "metadata should accept JSON" do
    @source.metadata = { "key" => "value", "number" => 123 }
    assert @source.valid?
    assert_equal({ "key" => "value", "number" => 123 }, @source.metadata)
  end
end
