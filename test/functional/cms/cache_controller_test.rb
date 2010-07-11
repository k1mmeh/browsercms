require File.join(File.dirname(__FILE__), '/../../test_helper')

class Cms::CacheControllerTest < ActionController::TestCase
  include Cms::ControllerTestHelper
  
  def setup
    DynamicView.write_all_to_disk!  # make sure that all db templates are on disk for functional tests
    login_as_cms_admin
  end
  
  def test_expire_cache
    #TODO: Implement Cache Expiration
  end
  
end
