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

  # s.rubyforge_project = "baseball_scorecard"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  # s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.executables << 'scorecard'
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
  s.add_dependency "markaby"
  s.add_dependency "hpricot"
  s.add_dependency "green_shoes"
  s.add_dependency "gameday_api"
  s.add_dependency "launchy"
end
