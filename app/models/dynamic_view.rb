class DynamicView < AbstractView

  # auto-write contents to filesystem
  after_save :write_file_to_disk
  # tidy up filesystem if name changed
  after_save :destroy_file_if_name_changed 

  def self.inherited(subclass)
    super if defined? super
  ensure
    subclass.class_eval do
      flush_cache_on_change
      is_publishable
      uses_soft_delete
      is_userstamped
      is_versioned :version_foreign_key => "abstract_view_id"

      before_validation :set_publish_on_save

      validates_presence_of :name, :format, :handler
      validates_uniqueness_of :name, :scope => [:format, :handler],
        :message => "Must have a unique combination of name, format and handler"

    end
  end

  def self.new_with_defaults(options={})
    new({:format => "html", :handler => "erb", :body => default_body}.merge(options))    
  end
  
  def write_file_to_disk
    if respond_to?(:file_path) && !file_path.blank?
      FileUtils.mkpath(File.dirname(file_path))
      open(file_path, 'w'){|f| f << body}
    end
  end
  
  def self.write_all_to_disk!
    all(:conditions => {:deleted => false}).each{|v| v.write_file_to_disk }
  end
  
  def self.default_body
    ""
  end

  def self.static_sister_class
    nil
  end

  protected

  def destroy_file_if_name_changed
    return unless @old_name.is_a?(String)

    self.class.remove_file_from_disk(File.join(self.class.file_path, @old_name))
  end
  
end
