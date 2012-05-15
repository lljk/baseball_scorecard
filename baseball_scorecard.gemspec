# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "baseball_scorecard/version"

Gem::Specification.new do |s|
  s.name        = "baseball_scorecard"
  s.version     = BaseballScorecard::VERSION
  s.authors     = ["j. kaiden"]
  s.email       = ["jakekaiden@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Baseball scorecard generator}
  s.description = %q{Baseball scorecard generator}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables << 'scorecard'
  s.require_paths = ["lib"]
  
  s.add_runtime_dependency "green_shoes"
  s.add_runtime_dependency "hpricot"
  s.add_runtime_dependency "gameday_api"
  s.add_runtime_dependency "launchy"
end
