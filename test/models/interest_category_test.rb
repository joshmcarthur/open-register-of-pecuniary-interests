require "test_helper"

class InterestCategoryTest < ActiveSupport::TestCase
  def setup
    @interest_category = InterestCategory.find_by!(key: "company_directorships_and_controlling_interests")
  end

  test "should be valid" do
    assert @interest_category.valid?
  end

  test "key should be present" do
    @interest_category.key = nil
    assert_not @interest_category.valid?
    assert_includes @interest_category.errors[:key], "can't be blank"
  end

  test "key should be unique" do
    duplicate_category = @interest_category.dup
    duplicate_category.label = "Different Label"
    assert_not duplicate_category.valid?
    assert_includes duplicate_category.errors[:key], "has already been taken"
  end

  test "label should be present" do
    @interest_category.label = nil
    assert_not @interest_category.valid?
    assert_includes @interest_category.errors[:label], "can't be blank"
  end

  test "should have many interests" do
    assert_respond_to @interest_category, :interests
  end

  test "should be able to create valid interest category" do
    new_category = InterestCategory.new(
      key: "test_category",
      label: "Test Category"
    )
    assert new_category.valid?
  end
end
