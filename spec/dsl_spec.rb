require 'volley'

root = File.expand_path("../../", __FILE__)

describe Volley::VolleyFile do
  it "should be able to load a volleyfile" do
    Volley::VolleyFile.load("#{root}/test/dsl/simple.volleyfile")
  end

  it "should have a project called test" do
    expect(Volley::Dsl.project("test")).not_to eq(nil)
  end

  it "should have a plan called publish" do
    expect(Volley::Dsl.project("test").plan("publish")).not_to eq(nil)
  end

  it "should have a plan called deploy" do
    expect(Volley::Dsl.project("test").plan("deploy")).not_to eq(nil)
  end
end