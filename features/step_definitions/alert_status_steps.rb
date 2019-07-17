Given("I required noch on my code") do
  
end

When("I call ok! method") do
  ok!
end

Then("alert status should change to {string}") do |string|
  got = get_current['status']
  fail "The status isn't as expected. Got #{got}" unless got == string
end

When("I call warning! method") do
  warning!
end

When("I call critical! method") do
  critical!
end

When("I call skip! method") do
  skip!
end