require "test_helper"

class ApplicationTest < ActiveSupport::TestCase
  test "should not save application without name" do
    application = Application.new
    assert_not application.save, "Should not save the application without a name"
  end

  test "should not save application with too long name" do
    application = Application.new(name: 'abcdefghijklmnopqrstu')
    assert_not application.save, "Should not save application with a too long name"
  end

  test "should not save application with too short name" do
    application = Application.new(name: 'abc')
    assert_not application.save, "Should not save application with a too short name"
  end

  test "should save application with name" do
    application = Application.new(name: 'testing')
    assert application.save, "Should save application with a name"
  end

  test "should update application with required fields" do
    application = Application.find('abcdef')
    assert application.update(name: 'abcde'), "Should update application with required field"
  end

  test "should not update application with too long name" do
    application = Application.find('abcdef')
    assert_not application.update(name: 'abcdefghijklmnopqrstu'), "Should not update application with too long name"
  end

  test "should not update application with too short name" do
    application = Application.find('abcdef')
    assert_not application.update(name: 'abc'), "Should not update application with too short name"
  end
end