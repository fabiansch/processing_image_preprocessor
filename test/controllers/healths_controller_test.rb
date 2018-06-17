require 'test_helper'

class HealthsControllerTest < ActionDispatch::IntegrationTest

  test "get responds with success" do
    get '/_health'
    assert_response :success
  end

end
