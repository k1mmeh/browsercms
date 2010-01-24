require File.join(File.dirname(__FILE__), '/../../test_helper')

class PageTemplateTest < ActiveSupport::TestCase
  def setup
    @page_template = Factory.build(:page_template, :name => "test")
    File.delete(@page_template.file_path) if File.exists?(@page_template.file_path)
  end
  
  def teardown
    File.delete(@page_template.file_path) if File.exists?(@page_template.file_path)    
  end
  
  def test_create_rename_and_destroy
    assert !File.exists?(@page_template.file_path), "template file already exists"
    assert_valid @page_template
    assert @page_template.save
    assert File.exists?(@page_template.file_path), "template file was not written to disk"
    old_file_path = @page_template.file_path
    @page_template.update_attributes!(:name => 'test_changed')
    assert @page_template.file_name.match(/^test_changed/), "file name has not updated following name change"
    assert !File.exist?(old_file_path), "old file still exists following name change"
    assert File.exist?(@page_template.file_path), "new file has not been created following name change"
    @page_template.destroy
    assert !File.exists?(@page_template.file_path), "template file was not removed on destroy"    
  end

  def test_for_valid_name
    assert_not_valid Factory.build(:page_template, :name => "Fancy")
    assert_not_valid Factory.build(:page_template, :name => "foo bar")
    assert_valid Factory.build(:page_template, :name => "subpage_1_column")
  end
  
  def test_find_by_file_name
    assert @page_template.save, "Could not save page template"
    assert_equal @page_template, PageTemplate.find_by_file_name("test.html.erb")
    assert_nil PageTemplate.find_by_file_name("fail.html.erb")
    assert_nil PageTemplate.find_by_file_name("fail.erb")
    assert_nil PageTemplate.find_by_file_name("fail")
    assert_nil PageTemplate.find_by_file_name(nil)  
  end
  
end