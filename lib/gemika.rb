require 'gemika/version'
require 'gemika/errors'
require 'gemika/env'
require 'gemika/database' if Gemika::Env.gem?('activerecord')
require 'gemika/matrix'
require 'gemika/rspec' if Gemika::Env.gem?('rspec')

# don't load tasks by default
