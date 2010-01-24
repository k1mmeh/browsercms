class Browsercms310 < ActiveRecord::Migration
  def self.up

    # Changes to DynamicView with regard to lighthouse ticket #266
    #
    rename_column(:dynamic_view_versions, :dynamic_view_id, :abstract_view_id)
    rename_table(:dynamic_views, :abstract_views)
    rename_table(:dynamic_view_versions, :abstract_view_versions)
    add_column(:pages, :template_file_id, :integer)
    add_column(:page_versions, :template_file_id, :integer)

    fs_path = PageTemplate.file_path
    files = Dir.new(fs_path).entries - ['.', '..']
    files.delete_if {|file| file.to_s.split(/\./).length != 3}

    files.each do |file|
      next if AbstractView.find_by_file_name(file)
      # cant find view in DB - create FsPageTemplate

      fs_template = FsPageTemplate.new_from_file_name(file)
      #puts "Creating FsPageTemplate file #{file}"
      fs_template.save
    end

    Page.reset_column_information
    
    Page.find(:all).each do |page|
      next unless page.template_file_name

      view = PageTemplate.find_by_file_name(page.template_file_name)
      view ||= FsPageTemplate.find_by_file_name(page.template_file_name)
      next unless view

      #puts "Updating Page #{page.id} with AbstractView #{view.id}"
      page.template_file_id = view.id
      page.publish_on_save = true
      page.save
    end
    #
    # End changes to DynamicView with regard to lighthouse ticket #266

  end

  def self.down

    # Changes to DynamicView with regard to lighthouse ticket #266
    #
    remove_column(:pages, :template_file_id)
    remove_column(:page_versions, :template_file_id)
    rename_column(:abstract_view_versions, :abstract_view_id, :dynamic_view_id)
    rename_table(:abstract_views, :dynamic_views)
    rename_table(:abstract_view_versions, :dynamic_view_versions)
    #
    # End changes to DynamicView with regard to lighthouse ticket #266
    
  end
end
