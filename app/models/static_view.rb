class StaticView < AbstractView

  # tidy up filesystem if name changed
  after_save :rename_file_if_name_changed

  def self.inherited(subclass)
    super if defined? super
  ensure
    subclass.class_eval do
      flush_cache_on_change
      is_publishable
      is_userstamped
      is_versioned :version_foreign_key => "abstract_view_id"

      before_validation :set_publish_on_save

      validates_presence_of :name, :format, :handler
      validates_uniqueness_of :name, :scope => [:format, :handler],
        :message => "Must have a unique combination of name, format and handler"

    end
  end

  def self.detect_and_load_new_templates
    fs_templates = ActionController::Base.view_paths.map{|p| Dir["#{p}/#{relative_path}/*"]}.flatten.map{|f| File.basename(f)}
    db_templates = all
    sister_db_templates = dynamic_sister_class.all
    new_templates = (fs_templates - db_templates.map {|t| t.file_name}) - sister_db_templates.map {|t| t.file_name}

    new_templates.each do |template|
      new_from_file_name(template).save!
    end
  end

  def self.all_templates(refresh = true)
    detect_and_load_new_templates if refresh

    return all
  end

  def self.new_from_file_name(file_name)
    parts = file_name.split(/\./)[0...3]
    new(:name => parts[0], :format => parts[1], :handler => parts[2])
  end

  def self.dynamic_sister_class
    nil
  end

  protected

  def rename_file_if_name_changed
    return unless @old_name.is_a?(String)

    if File.exists?(File.join(self.class.file_path, @old_name))
      File.rename(File.join(self.class.file_path, @old_name), file_path)
    end
  end
  
end
