# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simple3d/version'

Gem::Specification.new do |spec|
  spec.name          = "simple3d_mesh"
  spec.version       = Simple3d::MESH_VERSION
  spec.authors       = ["Misha Conway"]
  spec.email         = ["MishaAConway@gmail.com"]
  spec.summary       = %q{A simple to use 3d mesh}
  spec.description   = %q{A simple to use 3d mesh}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'geo3d'
  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
