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

describe Volley::Dsl::Plan do
  before(:each) do
    Volley.unload
    @project = Volley::Dsl::Project.project(:spec) do
      scm :git
      plan :publish do
        #nothing
      end
    end
    @plan = @project.plan(:publish)
  end

  it "should be able to define a plan" do
    expect(@plan).not_to be(nil)
  end

  it "should be able to define an action" do
    @plan.action :first do
      #nothing
    end
    expect(@plan.stages.count).to eq(3)
    expect(@plan.stages[:main].count).to eq(1)
  end

  it "should be able to access source" do
    expect {@plan.source.branch}.not_to raise_exception
  end

  it "should be able to access global config" do
    Volley.config.blarg = true
    expect do
      raise "fail" unless @plan.config.blarg == true
    end.not_to raise_exception
  end

  it "should be able to load another Volleyfile" do
    expect {@plan.load("#{root}/test/dsl/simple.volleyfile")}.not_to raise_exception
    expect(Volley::Dsl.project(:test)).not_to be(nil)
  end

  it "should handle arguments" do
    @plan.argument(:testarg)
    expect(@plan.arguments.count).to eq(3) # branch, version and testarg
    @plan.call(:args => ["testarg:true"])
    expect(@plan.args.testarg).to eq("true")
  end

  # boolean as strings because we test conversion later
  it "should handle argument defaults" do
    @plan.argument(:testarg, :default => "false")
    expect {@plan.call(:args => [])}.not_to raise_exception
    Volley::Log.debug "ARGS: #{@plan.args.inspect}"
    expect(@plan.args.testarg).to eq("false")
  end

  # boolean as strings because we test conversion later
  it "should handle arguments overriding defaults" do
    @plan.argument(:testarg, :default => "false")
    expect {@plan.call(:args => ["testarg:true"])}.not_to raise_exception
    expect(@plan.args.testarg).to eq("true")
  end

  it "should fail if required arguments aren't specified" do
    @plan.argument(:testarg, :required => true)
    expect {@plan.call(:args => [])}.to raise_exception
  end

  [
      ["boolean", "true", true],
      ["to_i", "1", 1],
      ["to_f", "1.12", 1.12],
  ].each do |arg|
    (type, original, value) = arg
    it "should handle converting argument: #{type}" do
      @plan.argument(type, :convert => type.to_sym)
      @plan.call(:args => ["#{type}:#{original}"])
      expect(@plan.args.send(type.to_sym)).to eq(value)
    end
  end
end