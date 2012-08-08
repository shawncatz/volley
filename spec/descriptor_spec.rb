require 'volley/descriptor'

describe Volley::Descriptor do
  [
      %w{spec@trunk:1 spec trunk 1},
      %w{spec/trunk/1 spec trunk 1},
      %w{spec-trunk-1 spec trunk 1},
      %w{spec:trunk:1 spec trunk 1},
      %w{spec\trunk\1 spec trunk 1},
      %w{spec@trunk spec trunk latest},
      %w{spec/trunk spec trunk latest},
      %w{spec:trunk spec trunk latest},
      %w{spec\trunk spec trunk latest},
  ].each do |a|
    (desc, project, branch, version) = a
    it "should handle format: '#{desc}'" do
      d = Volley::Descriptor.new(desc)
      expect(d).not_to be(nil)
      expect(d.project).to eq(project)
      expect(d.branch).to eq(branch)
      if version != "latest"
        expect(d.version).to eq(version)
      end
    end
  end

  %w{
    spec
    spec:
    spec~trunk
    spec:trunk:1:blarg
  }.each do |desc|
    it "should not handle format: '#{desc}'" do
      expect { Volley::Descriptor.new(desc) }.to raise_error(StandardError)
    end
  end

  it "should allow partials when specified" do
    expect { Volley::Descriptor.new("environment", :partial => true)}.not_to raise_exception
  end
end