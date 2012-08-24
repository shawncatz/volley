require 'volley/publisher/local'
require 'volley/publisher/amazons3'

root = File.expand_path("../../", __FILE__)

Volley::Log.add(:debug, "#{root}/log/volley.log")
Volley::Log.console_disable

shared_examples_for Volley::Publisher::Base do
  before(:all) do
    @remote = "#{root}/test/publisher/remote"
    @local  = "/opt/volley"
    FileUtils.mkdir_p(@remote)
    FileUtils.mkdir_p(@local)
    [@local, @remote].each { |d| %x{rm -rf #{d}/*} }
  end

  after(:all) do
    FileUtils.rm_rf(@remote)
    FileUtils.rm_rf(@local)
  end

  it "should be able to publish artifacts" do
    Dir.chdir("#{root}/test/")
    expect(@pub.push("spec", "trunk", "1", "./trunk-1.tgz")).to eq(true)
    expect(@pub.push("spec", "trunk", "2", "./trunk-1.tgz")).to eq(true)
    expect(@pub.push("spec", "staging", "1", "./trunk-1.tgz")).to eq(true)
    Dir.chdir(root)
  end

  it "should be able to retrieve an artifact" do
    expect(@pub.pull("spec", "trunk", "1")).to eq("#@local/spec/trunk/1/trunk-1.tgz")
  end

  it "should fail to retrieve a missing artifact" do
    expect{ @pub.pull("spec", "trunk", "15")}.to raise_error(Volley::Publisher::ArtifactMissing)
  end

  it "should be able to tell me the list of projects" do
    expect(@pub.projects).to match_array(%w{spec})
  end

  it "should be able to tell me the list of branches" do
    expect(@pub.branches("spec")).to match_array(%w{trunk staging})
  end

  it "should be able to tell me the list of versions" do
    expect(@pub.versions("spec", "trunk")).to match_array(%w{1 2})
  end

  it "should be able to tell me the list of files" do
    expect(@pub.contents("spec","trunk","2")).to match_array(%w{trunk-1.tgz})
  end

  it "should be able to get a remote volleyfile" do
    Dir.chdir("#{root}/test/project")
    expect(@pub.push("spec","trunk","3","Volleyfile")).to eq(true)
    Dir.chdir(root)
    expect(@pub.volleyfile("spec","trunk","3")).to match(/#@local\/Volleyfile-.*-.*/)
  end

  it "should be able to tell me the latest of a project and branch" do
    expect(@pub.latest("spec", "trunk")).to eq("spec/trunk/3")
  end

  it "should fail to publish a duplicate artifact" do
    expect(@pub.push("spec", "trunk", "1", "./trunk-1.tgz")).to eq(false)
  end

  it "should be able to force publish a duplicate artifact" do
    Dir.chdir("#{root}/test/")
    o = @pub.force
    @pub.force = true
    expect(@pub.push("spec", "trunk", "1", "./trunk-1.tgz")).to eq(true)
    @pub.force = o
    Dir.chdir(root)
  end

  it "should be able to delete a project" do
    expect(@pub.delete_project("spec")).to eq(true)
  end
end

describe Volley::Publisher::Local do
  it_behaves_like Volley::Publisher::Base

  before(:each) do
    @pub = Volley::Publisher::Local.new(:directory => @remote)
  end
end

describe Volley::Publisher::Amazons3 do
  it_behaves_like Volley::Publisher::Base

  before(:each) do
    @pub = Volley::Publisher::Amazons3.new(:aws_access_key_id     => "AKIAIWUGNGSUZWW5XVCQ",
                                           :aws_secret_access_key => "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",
                                           :bucket => "inqcloud-volley-test")
  end
end