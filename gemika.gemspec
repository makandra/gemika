$:.push File.expand_path("../lib", __FILE__)
require "gemika/version"

Gem::Specification.new do |s|
  s.name = 'gemika'
  s.version = Gemika::VERSION
  s.authors = ["Henning Koch"]
  s.email = 'henning.koch@makandra.de'
  s.homepage = 'https://github.com/makandra/gemika'
  s.summary = 'Helpers for testing Ruby gems'
  s.description = s.summary
  s.license = 'MIT'
  s.metadata = { 'rubygems_mfa_required' => 'true' }

  s.files         = `git ls-files`.split("\n").reject { |path| !File.exists?(path) || File.lstat(path).symlink? }
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n").reject { |path| !File.exists?(path) || File.lstat(path).symlink? }
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
