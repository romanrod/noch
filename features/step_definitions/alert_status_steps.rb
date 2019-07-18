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
end

When("I call {string} method with data like") do |method_name, data|
  send("#{method_name}", {data: JSON.parse(data)})
end

When("I call last_data method") do
  @result = last_data
end

Then("I should see the data") do |data|
  expected_data = JSON.parse(data)
  fail "The result isn't as expected. Got #{@result}. Expected: #{expected_data}" unless @result == expected_data
end

Then("nothing should happen") do
  fail "The result isn't as expected. Got #{@second_result} Expected #{@first_result}" unless @second_result == @first_result
end