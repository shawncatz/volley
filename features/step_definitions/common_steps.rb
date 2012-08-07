

Then /^I should receive an exception$/ do
  fail if @exception.nil?
end

Then /^I should not receive an exception$/ do
  fail unless @exception.nil?
end