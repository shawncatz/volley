require 'volley/publisher/local'
require 'volley/publisher/amazons3'

root = File.expand_path("../../", __FILE__)

Volley::Log.add(:debug, "#{root}/log/volley.log")
Volley::Log.console_disable

shared_examples_for Volley::Publisher::Base do
  before(:all) do
    FileUtils.mkdir_p("#{root}/test/publisher/remote")
    FileUtils.mkdir_p("#{root}/test/publisher/local")
  end

  after(:all) do
    FileUtils.rm_rf("#{root}/test/publisher")
  end

  it "should be able to publish artifacts" do
    Dir.chdir("#{root}/test/")
    expect(@pub.push("spec", "trunk", "1", "./trunk-1.tgz")).to eq(true)
    expect(@pub.push("spec", "trunk", "2", "./trunk-1.tgz")).to eq(true)
    expect(@pub.push("spec", "staging", "1", "./trunk-1.tgz")).to eq(true)
    Dir.chdir(root)
  end

  it "should be able to retrieve an artifact" do
    expect(@pub.pull("spec", "trunk", "1")).to eq("#{root}/test/publisher/local/spec/trunk/1/trunk-1.tgz")
  end

  it "should be able to tell me the list of projects" do
    expect(@pub.projects).to match_array(%w{spec})
  end

  it "should be able to tell me the list of branches" do
    expect(@pub.branches("spec")).to match_array(%w{trunk staging})
  end

  it "should be able to tell me the list of versions" do
    expect(@pub.versions("spec", "trunk")).to match_array(%w{1 2 latest})
  end

  it "should be able to tell me the latest of a project and branch" do
    expect(@pub.latest("spec", "trunk")).to eq("spec/trunk/2")
  end

  it "should throw an exeception when trying to publish a duplicate artifact" do
    expect { @pub.push("spec", "trunk", "1", "./trunk-1.tgz") }.to raise_error(StandardError)
  end

  it "should be able to delete a project" do
    expect(@pub.delete_project("spec")).to eq(true)
  end
end

describe Volley::Publisher::Local do
  it_behaves_like Volley::Publisher::Base
  remote = "#{root}/test/publisher/remote"
  local  = "#{root}/test/publisher/local"
  [local, remote].each { |d| %x{rm -rf #{d}/*} }

  after(:all) do
    %x{rm -rf #{root}/test/publisher}
  end

  before(:each) do
    @pub = Volley::Publisher::Local.new(:directory => remote, :local => local)
  end
end

#describe Volley::Publisher::Amazons3 do
#  it_behaves_like Volley::Publisher::Base
#
#  before(:each) do
#    @pub = Volley::Publisher::Amazons3.new(:aws_access_key_id     => "AKIAIWUGNGSUZWW5XVCQ",
#                                           :aws_secret_access_key => "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",
#                                           :bucket => "inqcloud-volley-test",
#                                           :local => "#{root}/test/publisher/local")
#  end
#end