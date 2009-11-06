
class JSInclude
  
  class << self
    attr_accessor :base_path, :inclue_tag, :enable_production, :cache, :cache_dir_name
  end
  self.base_path         = "public"
  self.inclue_tag        = "@include"           # You can change the TAG into anything as you like
  self.enable_production = false 
  self.cache             = {}                   #  required_file => merged_and_compressed_file
  self.cache_dir_name    = "js_include_cached"
  
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
      files = JSInclude.get_required_file_names(file_name)
      files.collect{|f| javascript_include_tag(f)}.join "\n"
    end
  end
  
  module Error
    class DeadEnd < Exception 
      def self.check dependency_stack, file
        raise(DeadEnd, "Dead End at:\n#{dependency_stack.push(file).inspect}") if dependency_stack.include? file
      end
    end
    class JsNotFound < Exception 
      def self.check file
        raise(JsNotFound, "Javascript file not found in #{file}") unless File.exists? file
      end
    end 
  end
  
  def self.get_required_file_names file_name
    full_file_name = File.join(base_path,file_name)
    if enable_production
      cached_file_name = cache[full_file_name]
      if cached_file_name and File.exists? File.join(base_path,cached_file_name)
        return cached_file_name
      else
        files = recursion_find_required_files file_name
        cached_file_name = merge_and_compress_files(files.collect{ |file|File.join(base_path,file) })
        cache[full_file_name] = cached_file_name
        return cached_file_name
      end
    else
      return recursion_find_required_files file_name 
    end
  end
  
  def self.merge_and_compress_files files
    file, filename = merge files
    return compress file, filename
  end
  
  def self.merge files
    content = files.collect{ |file| File.read file }.join "\n"
    # write to tmp file
    file_name = JSInclude.extract_js_file_name(files.last)+"_compressed.js"
    full_file_name = File.join(RAILS_ROOT, 'tmp', file_name)
    File.open(full_file_name, 'w'){ |file| file << content }
    return file_name, full_file_name
  end
  
  def self.extract_js_file_name str
    str.match(/[\w|\s]*\.js/).to_s.gsub(".js","")
  end
  
  def self.compress file_name, full_file_name
    puts "============== JSInclude ==============="
    puts "compressing #{file_name}"
    yui_compressor = File.join(RAILS_ROOT,"vendor/plugins/js_include/lib/yui-compressor.jar")
    result = `java -jar #{yui_compressor} --charset UTF-8 -o #{File.join(base_path,cache_dir_name,file_name)} #{full_file_name}`
    raise "YUI-Compressor error:\n #{result}" if $?.exitstatus != 0
    "/#{cache_dir_name}/#{file_name}"
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
    full_file_name = File.join(base_path,file_name)
    Error::JsNotFound.check full_file_name
    result = [] 
    path = file_name.match(/^.*\//)
    File.readlines( full_file_name ).each do |line|
      break unless line.chomp =~ /^\s*\/\/#{inclue_tag}\s*/
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