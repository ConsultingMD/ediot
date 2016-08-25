# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'grnds/ediot/version'

Gem::Specification.new do |spec|
  spec.name          = "grnds-ediot"
  spec.version       = Grnds::Ediot::VERSION
  spec.authors       = ["Brian Chamberlain"]
  spec.email         = ["brian.chamberlain@grandrounds.com"]

  spec.summary       = "EDI Online Transformer"
  spec.description   = "Don't be an EDIot. This gem contains libraries to transform an EDI X12 834 formated file (row based) to flattened CSV format (column based)"
  spec.homepage      = "https://github.com/ConsultingMD/ediot"
  spec.license       = "Copyright (c) 2016 Grand Rounds Inc, all rights reserved"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
    spec.metadata["yard.run"] = "yard" # to build full HTML docs.
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "parallel_tests", "~> 2.7.1"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "yard", "~> 0.9"
end
