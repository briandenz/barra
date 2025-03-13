require "test_helper"

class NeighborhoodsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get neighborhoods_index_url
    assert_response :success
  end
end
