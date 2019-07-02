
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "NOCH/version"

Gem::Specification.new do |spec|
  spec.name          = "NOCH"
  spec.version       = NOCH::VERSION
  spec.authors       = ["Roman"]
  spec.email         = ["roman.g.rodriguez@gmail.com"]

  spec.summary       = %q{Alerts on status change}
  spec.description   = %q{Notify alerts when status change}
  spec.homepage      = "https://github.com/romanrod/noch"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.dependency "redis"
  spec.dependency "slack-ruby-client"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
