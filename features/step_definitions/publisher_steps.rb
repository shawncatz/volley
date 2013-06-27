def publish(desc)
  pwd = Dir.pwd
  Dir.chdir("test/project")
  Volley::Dsl::VolleyFile.load("Volleyfile")
  Volley.process("publish", desc, {})
  Dir.chdir(pwd)
end

def deploy(desc)
  pwd = Dir.pwd
  Volley.process("deploy", desc, {})
  Dir.chdir(pwd)
end

Given /^I have a publisher with an empty repository$/ do
  @root ||= Volley.config.project_root
  %w{local remote}.each { |d| FileUtils.rm_rf("#@root/test/publisher/#{d}") }
  %w{local remote}.each { |d| FileUtils.mkdir_p("#@root/test/publisher/#{d}") }
  Volley::Dsl::VolleyFile.load("#@root/test/dsl/local_publisher.volleyfile")
  @pub = Volley::Dsl.publisher
end

Given /^I have a populated repository$/ do
  steps %Q{
    When I publish the artifact test/trunk/1
    And I publish the artifact test/staging/2
    And I publish the artifact test/trunk/3
    And I publish the artifact test/master/4
    And I publish the artifact test/staging/5
    And I publish the artifact test/trunk/7
  }
end

When /^I request a list of projects from the publisher$/ do
  @emptylist = @pub.projects
end

Then /^I should see an empty list$/ do
  fail unless @emptylist.count == 0
end

When /^I publish the artifact (.*)$/ do |desc|
  publish(desc)
end

When /^I deploy the artifact (.*)$/ do |desc|
  begin
    deploy(desc)
  rescue => e
    @exception = e
  end
end

When /^I publish a duplicate artifact (.*)$/ do |desc|
  steps %Q{
    When I publish the artifact #{desc}
  }
  begin
    @duplicate_published = publish(desc)
  rescue => e
    puts "exception: #{e.message}"
    @exception = e
  end
end

# TODO: make this work
When /^I force publish a duplicate artifact (.*)$/ do |desc|
  steps %Q{
    When I publish the artifact #{desc}
  }
  begin
    publish(desc)
  rescue => e
    puts "EXCEPTION"
    @exception = e
  end
end

Then /^there should be (.*) projects in the publisher$/ do |count|
  list = @pub.projects
  #puts "LIST:#{list.inspect}"
  fail unless list.count == count.to_i
end

Then /^the (.*) project should have (.*) branches$/ do |project, count|
  list = @pub.branches(project)
  #puts "LIST: #{list.inspect}"
  fail unless list.count == count.to_i
end

Then /^the latest of (.*)\/(.*) should be (.*)$/ do |project, branch, version|
  latest = @pub.latest(project, branch)
  fail unless latest == "#{project}/#{branch}/#{version}"
end
