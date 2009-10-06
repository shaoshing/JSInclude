
module JSInclude
  
  module Helper
    def self.js_include
      JSInclude.get_required_file_names.each do |file|
        javascript_include_tag file
      end
    end
  end
  
  def self.get_required_file_names
  end
  
end