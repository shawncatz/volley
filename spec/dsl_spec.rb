require 'volley'

root = File.expand_path("../../", __FILE__)

describe Volley::Dsl::VolleyFile do
  it "should be able to load a volleyfile" do
    Volley::Dsl::VolleyFile.load("#{root}/test/dsl/simple.volleyfile")
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

describe Volley::Dsl::Project do
  before(:each) do
    Volley.unload
  end

  it "should be able to define a project" do
    expect(Volley::Dsl::Project.project(:spec) { }).not_to be(nil)
  end

  it "should be able to define a project with an SCM configuration" do
    expect(Volley::Dsl::Project.project(:spec) { scm :git }).not_to be(nil)
  end

  it "should be able to define a project with a plan" do
    project = Volley::Dsl::Project.project(:spec) { plan(:publish) { } }
    expect(project).not_to be(nil)
    expect(project.plan(:publish)).not_to be(nil)
    expect(project.plan(:publish).project).to eq(project)
  end

  it "should be able to access config" do
    expect do
      Volley.config.blarg = true
      Volley::Dsl::Project.project(:spec) do
        raise "fail" unless config.blarg == true
      end
    end.not_to raise_exception
  end
end

describe Volley::Dsl::Plan do
  before(:each) do
    Volley.unload
    @project = Volley::Dsl::Project.project(:spec) { }
  end

  it "should be able to define a plan" do
    expect(@project.plan(:name) {}).not_to be(nil)
  end

  it "should be able to define a plan with an action" do
    plan = @project.plan(:name) do
      action :first do
        #nothing
      end
    end
    expect(plan).not_to be(nil)
    expect(plan.actions.count).to eq(3)
    expect(plan.actions[:main].count).to eq(1)
  end
end