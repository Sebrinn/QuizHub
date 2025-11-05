require "test_helper"

class Admin::InvitationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_invitations_index_url
    assert_response :success
  end

  test "should get new" do
    get admin_invitations_new_url
    assert_response :success
  end

  test "should get create" do
    get admin_invitations_create_url
    assert_response :success
  end
end
