
# Run Test : 
#   cd    path_to_JSInclude
#   spec  spec/js_include_spec.rb


require "lib/js_include"

describe "JSInclude" do
  
  describe "view helper [js_include] " do
    it "should call [javascript_include_tag] for each required files " do
      
      class A ; include JSInclude::Helper ; end
      a = A.new
      JSInclude.should_receive(:get_required_file_names).with("empty").and_return ["a.js","b.js"]
      a.should_receive(:javascript_include_tag).with("a.js").and_return ""
      a.should_receive(:javascript_include_tag).with("b.js").and_return ""
      a.js_include "empty"
    end
  end
  
  before(:each) do
    JSInclude::BASE_PATH = "test_files"
  end
  
  describe "[get_required_file_names]" do
    
    describe "success:" do
      it "normal dependency" do
        result = JSInclude::get_required_file_names "/dependency/normal/a.js"
        result.size.should == 4
        result[0].should == "/dependency/normal/d.js"
        result[1].should == "/dependency/normal/c.js"
        result[2].should == "/dependency/normal/b.js"
        result[3].should == "/dependency/normal/a.js"  
      end      
      
      it "complex" do
        result = JSInclude::get_required_file_names "/dependency/complex/a.js"
        result.size.should == 6
        result[0].should == "/dependency/complex/../normal/d.js"
        result[1].should == "/dependency/complex/e.js" 
        result[5].should == "/dependency/complex/a.js"
      end
      
      it "test file order" do
        result = JSInclude::get_required_file_names "/dependency/order/order.js"
        result.size.should == 3
        result[0].should == "/dependency/order/1.js"
        result[1].should == "/dependency/order/2.js" 
        result[2].should == "/dependency/order/order.js"
      end
      
    end
    
    describe "failure:" do
      it "when dead lock [a -> b -> a...]" do
        lambda{
          JSInclude::get_required_file_names "/dependency/error/a.js"
        }.should raise_error(JSInclude::Error::DeadEnd)
      end
    end
    
  end
  
  describe "[scan_include_tag]" do
    it "only scan lines begin with include tag [JSInclude::INCLUDE_TAG]" do
      files = JSInclude.scan_include_tag "/tag/normal.js"  
      files.size.should == 1
      files[0].should == "/tag/test.js"  
    end
    
    it "will stop if the beginning line is not start with tag" do
      files = JSInclude.scan_include_tag "/tag/begin.js"  
      files.size.should == 0
    end
    
    it "will stop if the up comming line is not start with tag" do
      files = JSInclude.scan_include_tag "/tag/end.js"  
      files.size.should == 1
      files[0].should == "/tag/test.js"
    end
    
    it "test path padding" do
      files = JSInclude.scan_include_tag "/tag/normal.js"  
      files[0].should == "/tag/test.js"  # pad with path "/tag/"
      files = JSInclude.scan_include_tag "/path.js"  
      files[1].should == "/test.js"      # no path padding
    end
    
    it "when file not exits" do
      lambda{
        JSInclude::get_required_file_names "/dependency/not_a_dir/a.js"
      }.should raise_error(JSInclude::Error::JsNotFound)
    end
      
  end
  
end