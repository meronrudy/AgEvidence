Gem::Specification.new do |spec|
  spec.name = "agevidence"
  spec.version = "0.1.0"
  spec.authors = ["AgEvidence"]
  spec.summary = "Ruby SDK for the AgEvidence active /api/v1 API and verifier delegation"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6"
  spec.files = Dir["lib/**/*.rb", "README.md"]
  spec.require_paths = ["lib"]
  spec.add_development_dependency "rake", ">= 13"
  spec.add_development_dependency "minitest", ">= 5"
end
