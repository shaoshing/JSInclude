
require "lib/js_include"

describe "JSInclude" do
  
  describe "view helper [js_include] " do
    it "should be defined" do
      JSInclude::Helper.respond_to?(:js_include).should be_true 
    end
    
    it "should call 'javascript_include_tag' for each required file " do
      JSInclude.should_receive(:get_required_file_names).and_return ["a.js","b.js"]
      JSInclude::Helper.should_receive(:javascript_include_tag).with("a.js")
      JSInclude::Helper.should_receive(:javascript_include_tag).with("b.js")
      
      JSInclude::Helper.js_include
    end
    
  end
  
end