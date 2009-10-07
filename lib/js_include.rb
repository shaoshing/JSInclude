
module JSInclude
  
  BASE_PATH   = "public"
  # You can change the TAG into anything as you like
  INCLUE_TAG  = "@include"
  
  module Helper
    # Just like javascript_include_tag, it will generate the <sceipt> tag
    # But it will also padding the included files.
    # === Example
    #   content of a.js:
    #     //@include b.js
    #     //@include c.js
    #   in your view file index.html.erb : 
    #     <%= js_include "/a.js" %>
    #     will become :
    #     <script src="/b.js?1254207084" type="text/javascript"></script>
    #     <script src="/c.js?1253971149" type="text/javascript"></script>
    #     <script src="/a.js?1254127786" type="text/javascript"></script>
    def js_include file_name
      tags = ""
      JSInclude.get_required_file_names(file_name).each do |file|
        tags += javascript_include_tag(file)+"\n"
      end
      tags
    end
  end
  
  module Error
    class DeadEnd < Exception 
      def self.check dependency_stack, file
        raise new("Dead End at:\n#{dependency_stack.push(file).inspect}") if dependency_stack.include? file
      end
    end
    class JsNotFound < Exception 
      def self.check file
        raise new("Js file not found:#{file}") unless File.exists? file
      end
    end 
  end
  
  def self.get_required_file_names file_name
    # The result order have to be reverse 
    recursion_find_required_files(file_name).reverse 
  end
  
  # Scan for INCLUDE_TAG and extract file_name after the TAG.
  # Return all the file_name after INCLUDE_TAG
  # Role:
  #   begin scan if the first line is start with TAG
  #   stop scan if the next line is not start with TAG
  #
  # === Example
  #   content of a.js:
  #     //@include b.js
  #     //@include c.js
  #   scan_include_tag "a.js" => ["c.js","b.js"] 
  #   read js_include_spec.rb for more example
  def self.scan_include_tag file_name
    full_file_name = "#{BASE_PATH}/#{file_name}"
    Error::JsNotFound.check full_file_name
    result = [] 
    path = file_name.match(/^.*\//)
    File.readlines( full_file_name ).each do |line|
      break unless line.chomp =~ /^\s*\/\/#{INCLUE_TAG}\s*/
      result << "#{path}#{$'.strip}"
    end
    result.reverse  # Reverse to work with [recursion_find_required_files]
  end
  
  # Do the same thing as:
  #   (C++) #include "name"
  # It will find the rest of files that a file needed and combine the correct files order.
  # ===Explanation
  #   [dependency_stack] is used to prevent deadend
  #   When dependency_stack == ["a","b","c"]
  #   And the pushing file name is "b"
  #   Then we can sure that it will be deadend like ["a","b","c","b","c"]
  def self.recursion_find_required_files current_file, dependency_stack = [], result = []
    Error::DeadEnd.check(dependency_stack, current_file)
    add_required_file(current_file, result)
    
    dependency_stack.push current_file
    scan_include_tag(current_file).each{|file| recursion_find_required_files(file, dependency_stack, result) }
    dependency_stack.pop
    result 
  end
  
  def self.add_required_file file, result
    # When result == ["a","b","c"]
    # And the file == "b"
    # Then the previous "b" have to be removed before add file
    index = result.find_index file
    result.delete_at index if index
    result << file
  end

end