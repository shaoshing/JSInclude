
# Run Test : 
#   cd    path_to_JSInclude
#   spec  spec/js_include_spec.rb


require "lib/js_include"

RAILS_ROOT = "./test_files"

describe "JSInclude" do
  
  before(:each) do
    JSInclude::ENABLE_PRODUCTION = false
    JSInclude::BASE_PATH = "test_files"
  end
  
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
    
    describe "when enable production and required file was" do
      before(:each) do
        JSInclude::ENABLE_PRODUCTION = true
        JSInclude::CACHE = {}
        JSInclude::CACHE_BASE_PATH   = "test_files/cache"
        @file_name = "a.js"
        @full_file_name = "#{JSInclude::BASE_PATH}/a.js"
      end
      describe "cached " do
        it "should return cached file name when the file was exist" do
          JSInclude::CACHE.should_receive(:[]).with(@full_file_name).and_return("#{JSInclude::CACHE_BASE_PATH}/compressed.js")
          JSInclude::get_required_file_names(@file_name).should ==  "#{JSInclude::CACHE_BASE_PATH}/compressed.js"
        end
        it "should involve [merge_and_compress_file] if file not exist" do
          JSInclude.stub! :recursion_find_required_files
          JSInclude::CACHE.should_receive(:[]).with(@full_file_name).and_return nil
          JSInclude.should_receive(:merge_and_compress_files)
          JSInclude::get_required_file_names(@file_name)
        end
      end
      describe "not cached" do
        it "should merge_and_compress_files, and then store cached file name and return that name" do
          JSInclude.should_receive(:recursion_find_required_files).with(@file_name).and_return(["a.js"])
          JSInclude.should_receive(:merge_and_compress_files).with(["a.js"]).and_return("cached_name.js")
          
          JSInclude::get_required_file_names(@file_name).should == "cached_name.js" 
          JSInclude::CACHE[@full_file_name].should == "cached_name.js" 
        end
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
  
  describe "[merge_and_compress_files]" do
    it "involve [merge] and [compress]" do
      JSInclude.should_receive(:merge).with(["some thing"]).and_return "merged"
      JSInclude.should_receive(:compress).with("merged").and_return "compressed"
      
      JSInclude.merge_and_compress_files(["some thing"]).should == "compressed" 
    end
    before(:each) do
      `mkdir test_files/tmp`      
    end
    after(:each) do
      `rm -Rf test_files/tmp`
    end
    describe "merging" do
      it "should merge files into one file" do
        file = JSInclude.merge ["#{JSInclude::BASE_PATH}/merging/a.js","#{JSInclude::BASE_PATH}/merging/b.js"]
        File.read(file).should ==  "a\nb"
      end
    end
    describe "compressing" do
    end
  end
  
  
  
end