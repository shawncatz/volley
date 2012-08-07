require 'volley'

root = File.expand_path("../../", __FILE__)

describe Volley::Meta do
  before(:each) do
    @meta = Volley::Meta.new("#{root}/test/meta.yml")
  end

  it "should be instantiated" do
    expect(@meta).not_to be(nil)
  end

  it "should be able to get current version for project" do
    expect(@meta["spec"]).to eq("trunk:2")
  end

  it "should be able to set new version for project" do
    @meta["spec"] = "trunk:3"
    expect(@meta["spec"]).to eq("trunk:3")
  end

  it "should be able to set version for new project" do
    expect {@meta["new"] = "blarg:1"}.not_to raise_exception
  end
end