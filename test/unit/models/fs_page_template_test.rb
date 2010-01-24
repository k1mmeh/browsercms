require File.join(File.dirname(__FILE__), '/../../test_helper')

class FsPageTemplateTest < ActiveSupport::TestCase
  def setup
    @page_template = Factory.build(:fs_page_template, :name => "fs_test")
    FileUtils.touch(@page_template.file_path) unless File.exists?(@page_template.file_path)
  end

  def teardown
    File.delete(@page_template.file_path) if File.exists?(@page_template.file_path)
  end

  def test_rename
    assert_valid @page_template
    @page_template.save!
    old_file_path = @page_template.file_path
    @page_template.update_attributes!(:name => 'fs_test_changed')
    assert @page_template.file_name.match(/^test_changed/), "file name has not updated following name change"
    assert !File.exist?(old_file_path), "old file still exists following name change"
    assert File.exist?(@page_template.file_path), "new file has not been created following name change"
  end

  def test_destroy
    assert_valid @page_template
    @page_template.destroy
    assert !File.exists?(@page_template.file_path), "template file was not removed on destroy"
  end

  def test_auto_load
    FileUtils.touch(File.join(FsPageTemplate.file_path, 'new_fs_template.html.erb')) unless File.exists?(File.join(FsPageTemplate.file_path, 'new_fs_template.html.erb'))

    before_count = FsPageTemplate.count
    FsPageTemplate.detect_and_load_new_templates
    assert FsPageTemplate.count > before_count, "template count has not increased after auto load"
    temp_template = FsPageTemplate.find_by_file_name('new_fs_template.html.erb')
    assert temp_template.is_a?(FsPageTemplate), "new FsPageTemplate was not auto created"
    assert temp_template.format == 'html', "new FsPageTemplate was auto created with the incorrect format"
    assert temp_template.handler == 'erb', "new FsPageTemplate was auto created with the incorrect handler"

    temp_template.destroy
  end

end