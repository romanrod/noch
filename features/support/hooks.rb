at_exit do
  begin
    File.delete 'my_script.rb'
  rescue
  end
end