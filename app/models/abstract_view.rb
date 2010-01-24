class AbstractView < ActiveRecord::Base

  before_save :detect_name_change
  after_destroy :remove_file_from_disk
  
  named_scope :with_file_name, lambda{|file_name|
    conditions = {:name => nil, :format => nil, :handler => nil}
    if file_name && (parts = file_name.split(".")).size == 3
      conditions[:name] = parts[0]
      conditions[:format] = parts[1]
      conditions[:handler] = parts[2]
    end
    {:conditions => conditions}
  }

  def self.find_by_file_name(file_name)
    with_file_name(file_name).first
  end

  # AbstractView interface requirements
  #
  def self.relative_path
    raise NoMethodError, "All concrete classes inheriting from AbstractView must implement self#relative_path"
  end
  #
  # End AbstractView interface requirements

  def self.base_path
    File.join(Rails.root, "tmp", "views")
  end

  def self.file_path
    File.join(base_path, relative_path)
  end

  def self.remove_file_from_disk(path)
    if File.exists?(path)
      File.delete(path)
    end
  end

  def file_path
    File.join(self.class.file_path, file_name)
  end

  def file_name
    "#{name}.#{format}.#{handler}"
  end

  def display_name
    self.class.display_name(file_name)
  end

  def set_publish_on_save
    self.publish_on_save = true
  end

  protected

  def remove_file_from_disk
    self.class.remove_file_from_disk(file_path)
  end
  
  # @old_name will be set to the previous file_name if the file_name has been changed
  def detect_name_change
    return true if new_record?

    old_name = self.class.find(self.id).file_name
    @old_name = old_name unless old_name == file_name
    return true
  end
  
end
