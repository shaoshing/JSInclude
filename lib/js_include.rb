
module JSInclude
  
  module Helper
    def self.js_include file_name
      JSInclude.get_required_file_names(file_name).each do |file|
        javascript_include_tag file
      end
    end
  end
  
  def self.get_required_file_names file_name
    scan_include_tag file_name
  end
  
  def self.scan_include_tag file_name
    
  end
  
end