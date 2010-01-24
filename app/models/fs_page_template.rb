class FsPageTemplate < StaticView

  def self.relative_path
    File.join("layouts", "templates")
  end
  
  def self.display_name(file_name)
    name, format, handler = file_name.split('.')
    "#{name.titleize} (#{format}/#{handler})"
  end

  def self.dynamic_sister_class
    PageTemplate
  end

end
