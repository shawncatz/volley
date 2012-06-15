# -*- encoding: utf-8 -*-
require File.expand_path('../lib/volley/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Shawn Catanzarite"]
  gem.email         = ["scatanzarite@gmail.com"]
  gem.description   = %q{PubSub Deployment tool}
  gem.summary       = %q{PubSub Deployment tool}
  gem.homepage      = "http://github.com/shawncatz/volley"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "volley"
  gem.require_paths = ["lib"]
  gem.version       = Volley::Version::STRING

  # command line
  gem.add_dependency "clamp"

  # talk to cloud
  gem.add_dependency "fog"

  gem.add_dependency "activesupport"

  gem.add_dependency "awesome_print"

  gem.add_dependency "mixlib-shellout"
end
