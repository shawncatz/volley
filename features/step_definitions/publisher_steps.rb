def publish(pr, br, vr)
  pwd = Dir.pwd
  Dir.chdir("test/project")
  Volley::VolleyFile.load("Volleyfile")
  Volley.process(:project => pr, :plan => "publish", :branch => br, :version => vr)
  Dir.chdir(pwd)
end

def deploy(pr, br, vr)
  pwd = Dir.pwd
  Volley.process(:project => pr, :plan => "deploy", :branch => br, :version => vr)
  Dir.chdir(pwd)
end

Given /^I have a publisher with an empty repository$/ do
  %w{local remote}.each { |d| FileUtils.rm_rf("test/publisher/#{d}") }
  %w{local remote}.each { |d| FileUtils.mkdir_p("test/publisher/#{d}") }
  Volley::VolleyFile.load("test/dsl/local_publisher.volleyfile")
  Volley::Log.console_disable
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

Then /^I should receive an exception$/ do
  fail if @exception.nil?
end

Then /^I should not receive an exception$/ do
  fail unless @exception.nil?
end

When /^I publish the artifact (.*)\/(.*)\/(.*)$/ do |pr, br, vr|
  publish(pr, br, vr)
end

When /^I deploy the artifact (.*)\/(.*)\/(.*)$/ do |pr, br, vr|
  begin
    deploy(pr,br,vr)
  rescue => e
    @exception = e
  end
end

When /^I publish a duplicate artifact (.*)\/(.*)\/(.*)$/ do |pr, br, vr|
  steps %Q{
    When I publish the artifact #{pr}/#{br}/#{vr}
  }
  begin
    publish(pr, br, vr)
  rescue => e
    @exception = e
  end
end

# TODO: make this work
When /^I force publish a duplicate artifact (.*)\/(.*)\/(.*)$/ do |pr, br, vr|
  steps %Q{
    When I publish the artifact #{pr}/#{br}/#{vr}
        }
  begin
    publish(pr, br, vr)
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
  fail unless list.count == count.to_i
end

Then /^the latest of (.*)\/(.*) should be (.*)$/ do |project, branch, version|
  latest = @pub.latest(project, branch)
  fail unless latest == "#{project}/#{branch}/#{version}"
end