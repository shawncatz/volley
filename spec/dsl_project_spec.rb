require 'volley'

root = File.expand_path("../../", __FILE__)

describe Volley::Dsl::Project do
  before(:each) do
    Volley.unload
    @project = Volley::Dsl::Project.project(:spec) { }
  end

  it "should be able to define a project" do
    expect(@project).not_to be(nil)
  end

  it "should be able to define a project with an SCM configuration" do
    expect(@project.scm :git).not_to be(nil)
  end

  it "should not allow the same project name to used more than once" do
    expect {Volley::Dsl::Project.project(:spec) { }}.to raise_exception
  end

  it "should be able to define a project with a plan" do
    @project.plan(:publish) {}
    plan = @project.plan(:publish)
    expect(plan).not_to be(nil)
    expect(plan.project).to eq(@project)
  end

  it "should be able to access global config" do
    Volley.config.blarg = true
    expect do
      raise "fail" unless @project.config.blarg == true
    end.not_to raise_exception
  end
end