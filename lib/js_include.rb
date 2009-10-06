
module JSInclude
  
  module Helper
    def self.js_include file_name
      JSInclude.get_required_file_names(file_name).each do |file|
        javascript_include_tag file
      end
    end
  end
  
  def self.get_required_file_names file_name
    current_file = nil
    pending_files = [file_name]
    result = []
    dependency = []
    
    until pending_files.empty?
      current_file = pending_files.pop
      raise "出现死循环，\n#{dependency.inspect}"  if dependency.include? current_file
      
      dependency.push current_file
      index = result.find_index current_file
      result.delete_at index if index
      result << current_file
      dependency.pop
      
      pending_files += scan_include_tag(current_file)
    end
    
    result.reverse 
  end
  
  BASE_PATH = "public"
  INCLUE_TAG = "@include"
  def self.scan_include_tag file_name
    result = [] 
    path = file_name.match(/^.*\//)
    File.readlines("#{BASE_PATH}/#{file_name}").each do |line|
      break unless line.chomp =~ /^\s*\/\/#{INCLUE_TAG}\s*/
      result << "#{path}#{$'.strip}"
    end
    result
  end
  
end