require File.join(File.dirname(__FILE__), '/../../test_helper')

class Cms::DashboardControllerTest < ActionController::TestCase
  include Cms::ControllerTestHelper
  
  def setup
    DynamicView.write_all_to_disk!  # make sure that all db templates are on disk for functional tests
    login_as_cms_admin
  end
  
  def test_index
    get :index
    
    assert_response :success
    assert_select "title", "Dashboard"
  end
end
