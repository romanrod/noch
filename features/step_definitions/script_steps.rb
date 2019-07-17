Given("I create a script with the name {string} like follows") do |filename, code|
  IO.write filename, code
end

When("I run the script with name {string}") do |filename|
  @output = `ruby #{filename}`
end

Then("alert name should print {string}") do |expected|
  fail "Cannot find expected output. got [#{@output}]" unless @output == expected
end