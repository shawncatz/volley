require 'volley'

root = File.expand_path("../../", __FILE__)

describe Volley::Dsl::Plan do
  before(:each) do
    Volley.unload
    @project = Volley::Dsl::Project.project(:spec) do
      scm :git
      plan :publish do
        #nothing
      end
      plan :notremote do
        remote false

      end
    end
    @plan = @project.plan(:publish)
    @notremote = @project.plan(:notremote)
  end

  it "should be able to define a plan" do
    expect(@plan).not_to be(nil)
  end

  it "should be able to define an action" do
    @plan.action :first do
      #nothing
    end
    expect(@plan.stages.count).to eq(3)
    expect(@plan.stages[:main].actions.count).to eq(1)
  end

  it "should be able to define an action in another stage" do
    @plan.action :second, :post do
      expect(@plan.stages.count).to eq(3)
      expect(@plan.stages[:main].actions.count).to eq(1)
      expect(@plan.stages[:post].actions.count).to eq(1)
    end
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
    expect(@plan.arguments.count).to eq(2) # descriptor and testarg
    @plan.call(:args => {:descriptor => "test@trunk/1",:testarg => "true"})
    expect(@plan.args.testarg).to eq("true")
  end

  it "should handle arguments (with remote false)" do
    @notremote.argument(:testarg)
    expect(@notremote.arguments.count).to eq(2) # descriptor and testarg
    @notremote.call(:args => {:testarg => "true"})
    expect(@notremote.args.testarg).to eq("true")
  end

  # boolean as strings because we test conversion later
  it "should handle argument defaults" do
    @plan.argument(:testarg, :default => "false")
    expect {@plan.call(:args => {:descriptor => "test@trunk/2"})}.not_to raise_exception
    expect(@plan.args.testarg).to eq("false")
  end

  # boolean as strings because we test conversion later
  it "should handle arguments overriding defaults" do
    @plan.argument(:testarg, :default => "false")
    expect {@plan.call(:args => {:descriptor => "test@trunk/3",:testarg => "true"})}.not_to raise_exception
    expect(@plan.args.testarg).to eq("true")
  end

  it "should fail if required arguments aren't specified" do
    expect {@plan.call(:args => {})}.to raise_exception
  end

  [
      ["boolean", "true", true],
      ["descriptor", "test@trunk/5", Volley::Descriptor.new("test@trunk/5")],
      ["to_i", "1", 1],
      ["to_f", "1.12", 1.12],
  ].each do |arg|
    (type, original, value) = arg
    it "should handle converting argument: #{type}" do
      @plan.argument(type, :convert => type.to_sym)
      @plan.call(:args => {:descriptor => "test@trunk/6",type.to_sym => "#{original}"})
      expect(@plan.args.send(type.to_sym)).to eq(value)
    end
  end
end