# encoding: utf-8
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "fluent-plugin-dynamodb"
  gem.description = "Amazon DynamoDB output plugin for Fluent event collector"
  gem.homepage    = "https://github.com/gonsuke/fluent-plugin-dynamodb"
  gem.summary     = gem.description
  gem.license     = "Apache-2.0"
  gem.version     = File.read("VERSION").strip
  gem.authors     = ["Takashi Matsuno"]
  gem.email       = "g0n5uk3@gmail.com"
  gem.has_rdoc    = false
  #gem.platform    = Gem::Platform::RUBY
  gem.files       = `git ls-files`.split("\n")
  gem.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.add_dependency "fluentd", [">= 0.10.0", "< 2"]
  gem.add_dependency "aws-sdk-v1", ">= 1.5.2"
  gem.add_dependency "uuidtools", "~> 2.1.0"
  gem.add_development_dependency "rake", ">= 0.9.2"
  gem.add_development_dependency "test-unit", ">= 3.1.0"
end
