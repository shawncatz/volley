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

  gem.add_dependency "clamp", "~> 0.6.1"
  gem.add_dependency "fog", "~> 1.12.1"
  gem.add_dependency "activesupport", "~> 3.2.13"
  gem.add_dependency "mixlib-shellout", "~> 1.1.0"
  gem.add_dependency "yell", "~> 1.3.0"
  gem.add_dependency "docopt", "~> 0.5.0"
  gem.add_dependency "daemons", "~> 1.1.9"
end
