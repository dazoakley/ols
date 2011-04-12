# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ols_client/version"

Gem::Specification.new do |s|
  s.name        = "ols_client"
  s.version     = OlsClient::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["TODO: Write your name"]
  s.email       = ["TODO: Write your email address"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "ols_client"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency "rubytree"
  s.add_dependency "sequel"
  s.add_dependency "mysql2"
  s.add_dependency "json"
  
  s.add_development_dependency "rake"
  s.add_development_dependency "shoulda"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "simplecov-rcov"
end
