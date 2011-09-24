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
  s.summary     = %q{A simple wrapper around the EBI's Ontology Lookup Service (OLS)}
  s.description = %q{
    OLS provides a simple interface to the EBI's Ontology Lookup Service (http://www.ebi.ac.uk/ontology-lookup/).
    It provides an easy lookup of ontology terms and automagically builds up ontology trees for you.
  }

  s.rubyforge_project = "ols"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency "savon"
  
  s.add_development_dependency "rake"
  s.add_development_dependency "shoulda"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "simplecov-rcov"
  s.add_development_dependency "awesome_print"
end
