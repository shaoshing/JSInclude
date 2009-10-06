
module JSInclude
  
  BASE_PATH   = "public"
  INCLUE_TAG  = "@include"
  
  module Helper
    def js_include file_name
      tags = ""
      JSInclude.get_required_file_names(file_name).each do |file|
        tags += javascript_include_tag(file)+"\n"
      end
      tags
    end
  end
  
  module Error
    class DeadLock    < Exception ; end
    class JsNotFound  < Exception ; end 
  end
  
  def self.get_required_file_names file_name
    recursion_find_required_files(file_name).reverse 
  end
  
  def self.scan_include_tag file_name
    result = [] 
    path = file_name.match(/^.*\//)
    full_file_name = "#{BASE_PATH}/#{file_name}"
    raise Error::JsNotFound.new("文件不存在：#{full_file_name}") unless File.exists? full_file_name
    File.readlines( full_file_name ).each do |line|
      break unless line.chomp =~ /^\s*\/\/#{INCLUE_TAG}\s*/
      result << "#{path}#{$'.strip}"
    end
    result.reverse
  end
  
  def self.recursion_find_required_files current_file, dependency = [], result = []
    raise Error::DeadLock.new("出现死循环，\n#{dependency.inspect}")  if dependency.include? current_file
    add_required_file current_file, result
    dependency.push current_file
    scan_include_tag(current_file).each{|file| recursion_find_required_files(file, dependency, result) }
    dependency.pop
    result 
  end
  
  def self.add_required_file file, result
    index = result.find_index file
    result.delete_at index if index
    result << file
  end
  
end