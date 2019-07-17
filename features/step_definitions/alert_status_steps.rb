Given("I required noch on my code") do
  
end

When("I call ok! method") do
  @result = ok!
end

Then("alert status should change to {string}") do |string|
  got = get_current['status']
  fail "The status isn't as expected. Got #{got}" unless got == string
end

When("I call warning! method") do
  @result = warning!
end

When("I call critical! method") do
  @result = critical!
end

When("I call skip! method") do
  @result = skip!
end

When("I call {string} method") do |meth|
  @first_result = send("#{meth}")
end

When("I call {string} method again") do |meth|
  @second_result = send("#{meth}")
  byebug
  puts
end

Then("nothing should happen") do
  byebug
  puts 'bla'
end