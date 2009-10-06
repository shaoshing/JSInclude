
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
  
  BASE_PATH = "public"
  INCLUE_TAG = "@include"
  def self.scan_include_tag file_name
    result = [] 
    path = file_name.match /^.*\//
    File.readlines("#{BASE_PATH}/#{file_name}").each do |line|
      break unless line.chomp =~ /^\s*\/\/#{INCLUE_TAG}\s*/
      result << "#{path}#{$'.strip}"
    end
    result
  end
  
end