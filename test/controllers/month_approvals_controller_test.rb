require 'test_helper'

class MonthApprovalsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get month_approvals_new_url
    assert_response :success
  end

end
