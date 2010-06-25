class Browsercms311 < ActiveRecord::Migration

  def self.up
    # Changes to DynamicView with regard to lighthouse ticket #266
    #
    # add new columns and tables related to dynamic views
    rename_column(:dynamic_view_versions, :dynamic_view_id, :abstract_view_id)
    rename_table(:dynamic_views, :abstract_views)
    rename_table(:dynamic_view_versions, :abstract_view_versions)
    add_column(:pages, :template_file_id, :integer)
    add_column(:page_versions, :template_file_id, :integer)

    fs_path = PageTemplate.file_path
    files = []    
    if File.exist?(fs_path)
      files = Dir.new(fs_path).entries - ['.', '..']
      files.delete_if {|file| file.to_s.split(/\./).length != 3}
    end

    # Find all existing file system layouts and make FsPageTemplates for them if they 
    # dont already exist in some form of AbstractView.
    files.each do |file|
      next if AbstractView.find_by_file_name(file)
      # cant find view in DB - create FsPageTemplate

      puts "creating new FsPageTemplate named #{file}"
      fs_template = FsPageTemplate.new_from_file_name(file)
      fs_template.save
    end
    
    Page.find(:all).each do |page|
      # template names should be of format <name>.<format>.<handler> ~ /^[^.]+\.[^.]+\.[^.]+$/
      if page[:template_file_name] && page[:template_file_name].match(/^[^.]+\.[^.]+\.[^.]+$/)
        # if your page has an existing filename, find a PageTemplate or FsPageTemplate of that 
        # name.  Else create a PageTemplate with default content.
        view = find_or_create_template(page[:template_file_name])
      else
        # else if your page has no existing filename (true for the seed data, if loaded with
        # the new page_template code), find the existing PageTemplate or FsPageTemplate named
        # default.  Else create new default PageTemplate.
        view = find_or_create_template('default.html.erb')
      end

      # Assign the page template to the page
      # This is done in raw SQL so as to ensure that versioning is not triggered
      execute "UPDATE pages SET template_file_id = #{view.id.to_i} WHERE id = #{page.id.to_i}"

      # attempt to restore links to templates in page versions.  if the template has been removed,
      # we end up creating a dummy one - oh well, no harm done
      page.versions.each do |version|
        # template names should be of format <name>.<format>.<handler> ~ /^[^.]+\.[^.]+\.[^.]+$/
        if version[:template_file_name] && page[:template_file_name].match(/^[^.]+\.[^.]+\.[^.]+$/)
          v_view = find_or_create_template(page[:template_file_name])
        else
          v_view = find_or_create_template('default.html.erb')
        end
        # Assign the page template to the page version
        # Again, this is done in raw SQL so as to ensure that versioning is not triggered
        execute "UPDATE page_versions SET template_file_id = #{v_view.id.to_i} WHERE id = #{version.id.to_i}"
      end
    end

    # remove old unused columns
    remove_column(:pages, :template_file_name)
    remove_column(:page_versions, :template_file_name)
    #
    # End changes to DynamicView with regard to lighthouse ticket #266
  end

  def self.down
    # Changes to DynamicView with regard to lighthouse ticket #266
    #
    # restore old columns
    add_column(:pages, :template_file_name, :string)
    add_column(:page_versions, :template_file_name, :string)

    Page.find(:all).each do |page|
      view = page.page_template
      if view
        # restore template_file_name from page_template
        execute "UPDATE pages SET template_file_name = '#{view.file_name.to_s}' WHERE id = #{page.id.to_i}"
      else
        # no page_template is assigned (bad), give it the default template
        default_view = find_or_create_template('default.html.erb')
        puts "Could not locate template filename to associate to page with ID: #{page.id}. Assigning to default.html.erb"
        execute "UPDATE pages SET template_file_name = 'default.html.erb' WHERE id = #{page.id.to_i}"
      end

      page.versions.each do |version|
        # use #template_file_id instead of #page_tempate as this is a page_version
        view = AbstractView.find_by_id(version.template_file_id.to_i)
        if view
          # restore the template_file_name from template_file_id
          execute "UPDATE page_versions SET template_file_name = '#{view.file_name.to_s}' WHERE id = #{version.id.to_i}"
        else
          # no page_template is assigned (bad), give it the default template
          default_view = find_or_create_template('default.html.erb')
          puts "Could not locate template filename to associate to page version with page ID: #{version.page_id} and version: #{version.version}. Assigning to default.html.erb"
          execute "UPDATE pages SET template_file_name = 'default.html.erb' WHERE id = #{version.id.to_i}"
        end
      end
    end

    # remove new columns and tables
    remove_column(:pages, :template_file_id)
    remove_column(:page_versions, :template_file_id)
    rename_column(:abstract_view_versions, :abstract_view_id, :dynamic_view_id)
    rename_table(:abstract_views, :dynamic_views)
    rename_table(:abstract_view_versions, :dynamic_view_versions)
    #
    # End changes to DynamicView with regard to lighthouse ticket #266
  end

  private

  # repeated method to find or create PageTemplates and FsPageTemplates by name
  def self.find_or_create_template(name)
    view = PageTemplate.find_by_file_name(name.to_s)
    view ||= FsPageTemplate.find_by_file_name(name.to_s)
    unless view
      puts "Adding new template called #{name}"
      view = PageTemplate.create!(:name => name.to_s.split('.').first, :format => 'html', :handler => 'erb', :body => PageTemplate.default_body)
    end

    return view
  end

end
