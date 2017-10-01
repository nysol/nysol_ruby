# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "nysolmod"
  spec.version       = "0.0.1"
  spec.authors       = ["nysol"]
  spec.email         = ["info@nysol.jp"]
  spec.summary       = %q{Tools for nysol ruby tools}
  spec.description   = %q{refer : http://www.nysol.jp/}
  spec.homepage      = "http://www.nysol.jp/"
	spec.extensions = ['ext/_nysolshell_core/extconf.rb']

	spec.platform = Gem::Platform::RUBY 
  spec.files         = Dir.glob([
		"lib/*.rb",
		"ext/nysolshell_core/*.cpp",
		"ext/nysolshell_core/help/en/*.h",
		"ext/nysolshell_core/help/jp/*.h",
		"ext/nysolshell_core/*.h" 
		])
	spec.extensions=[
		"ext/nysolshell_core/extconf.rb",
	]
  spec.require_paths = ["lib"]
	spec.add_development_dependency 'rake-compiler'
end
