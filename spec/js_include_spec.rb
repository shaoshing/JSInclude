
# Run Test : 
#   cd    path_to_JSInclude/
#   spec  spec/js_include_spec.rb


require "lib/js_include"

describe "JSInclude" do
  
  describe "view helper [js_include] " do
    it "should be defined" do
      JSInclude::Helper.respond_to?(:js_include).should be_true 
    end
    
    it "should call [javascript_include_tag] for each required files " do
      JSInclude.should_receive(:get_required_file_names).with("empty").and_return ["a.js","b.js"]
      JSInclude::Helper.should_receive(:javascript_include_tag).with("a.js")
      JSInclude::Helper.should_receive(:javascript_include_tag).with("b.js")
      
      JSInclude::Helper.js_include "empty"
    end
  end
  
  describe "[get_required_file_names]" do
    it "should call [scan_include_tag]" do
      JSInclude.should_receive(:scan_include_tag).with "name"
      JSInclude.get_required_file_names "name"
    end
  end
  
  describe "[scan_include_tag]" do
    it "should scan specify file for include tag '@include' and return file names" do
    end
  end
  
  
end