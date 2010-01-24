require File.join(File.dirname(__FILE__), '/../../test_helper')

class Cms::DynamicViewsControllerTest < ActionController::TestCase
  include Cms::ControllerTestHelper

  def setup
    login_as_cms_admin
  end
  
  def test_index
    @deleted_page_template = Factory(:page_template, :name => "deleted")
    @deleted_page_template.destroy

    @page_template = Factory(:page_template, :name => "test")

    @fs_deleted_page_template = Factory(:fs_page_template, :name => "fs_deleted")
    @fs_deleted_page_template.destroy

    @fs_page_template = Factory(:fs_page_template, :name => "fs_test")
    
    def @request.request_uri
      "/cms/page_templates"
    end
    get :index
    
    assert_response :success
    #log @response.body
    assert_select "#page_template_#{@page_template.id} div", "Test (html/erb)"
    assert_select "#page_template_#{@page_template.id} div", "CMS"
    assert_select "#page_template_#{@fs_page_template.id} div", "Fs Test (html/erb)"
    assert_select "#page_template_#{@fs_page_template.id} div", "Filesystem"
    assert_select "#page_template_#{@deleted_page_template.id} div", 
      :text => "Deleted (html/erb)", :count => 0
    assert_select "#page_template_#{@fs_deleted_page_template.id} div",
      :text => "Fs Deleted (html/erb)", :count => 0

  end

  def test_edit
    @page_template = Factory(:page_template, :name => "test_edit")
    @fs_page_template = Factory(:fs_page_template, :name => "fs_test_edit")

    get :edit, :id => @page_template.id

    # CMS page templates should allow editable Name, Format, Handler and Body
    assert_select "form#edit_page_template_#{@page_template.id} label", "Name"
    assert_select "form#edit_page_template_#{@page_template.id} label", "Format"
    assert_select "form#edit_page_template_#{@page_template.id} label", "Handler"
    assert_select "form#edit_page_template_#{@page_template.id} label", "Body"

    get :edit, :id => @fs_page_template.id

    # Filesystem page templates should only allow editable Name
    assert_select "form#edit_fs_page_template_#{@fs_page_template.id} label", "Name"
    assert_select "form#edit_fs_page_template_#{@fs_page_template.id} label",
      :text => "Format", :count => 0
    assert_select "form#edit_fs_page_template_#{@fs_page_template.id} label",
      :text => "Handler", :count => 0
    assert_select "form#edit_fs_page_template_#{@fs_page_template.id} label",
      :text => "Body", :count => 0
  end
  
end