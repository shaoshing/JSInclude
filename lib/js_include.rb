
module JSInclude
  
  BASE_PATH           = "public"
  INCLUE_TAG          = "@include"  # You can change the TAG into anything as you like
  ENABLE_PRODUCTION   = false 
  CACHE               = {}          #  required_file => merged_and_compressed_file
  CACHE_BASE_PATH     = "public/js_include_cached"
  
  module Helper
    # Just like javascript_include_tag, it will generate the <script> tag
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
        raise new("Javascript file not found in #{file}") unless File.exists? file
      end
    end 
  end
  
  def self.get_required_file_names file_name
    full_file_name = "#{BASE_PATH}/#{file_name}"
    if JSInclude::ENABLE_PRODUCTION
      cached_file_name = JSInclude::CACHE[full_file_name]
      if cached_file_name and File.exists? cached_file_name
        return cached_file_name
      else
        cached_file_name = merge_and_compress_files(recursion_find_required_files file_name)
        JSInclude::CACHE[full_file_name] = cached_file_name
        return cached_file_name
      end
    else
      return recursion_find_required_files file_name 
    end
  end
  
  def self.merge_and_compress_files files
    return compress(merge files)
  end
  
  def self.merge files
    content = files.collect{ |file| File.read file }.join "\n"
    # write to tmp file
    file_name = files.last.match(/[\w|\s]*\.js/).to_s.gsub(".js","")+"_compressed.js"
    full_file_name = File.join(RAILS_ROOT, '/tmp/', file_name)
    File.open(full_file_name, 'w'){ |file| file << content }
    full_file_name
  end
  
  def self.compress file
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
    
    # the final result may be [b.js,a.js], so it has to be reverse to the right order
    if dependency_stack.empty? then result.reverse else result end
  end
  
  def self.add_required_file file, result
    # When result == ["a","b","c"]
    # And the file == "b"
    # Then the previous "b" have to be removed before add file
    index = result.index file
    result.delete_at index if index
    result << file
  end

end