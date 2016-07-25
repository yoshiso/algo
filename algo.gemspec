# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'algo/version'

Gem::Specification.new do |spec|
  spec.name          = "algo"
  spec.version       = Algo::VERSION
  spec.authors       = ["yoshiso"]
  spec.email         = ["nya060@gmail.com"]

  spec.summary       = %q{Docker container orchestration tool for swarm cluster.}
  spec.description   = %q{Docker container orchestration tool for swarm cluster.}
  spec.homepage      = "https://github.com/yoshiso/algo"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activesupport', '~> 4.0'
  spec.add_dependency 'excon', '0.51.0'
  spec.add_dependency 'thor'
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.10"
end
