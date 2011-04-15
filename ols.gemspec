# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ols/version"

Gem::Specification.new do |s|
  s.name        = "ols"
  s.version     = OLS::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Darren Oakley"]
  s.email       = ["daz.oakley@gmail.com"]
  s.homepage    = "https://github.com/dazoakley/ols"
  s.summary     = %q{}
  s.description = %q{}

  s.rubyforge_project = "ols"

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
