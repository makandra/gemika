require 'gemika/version'
require 'gemika/env'
require 'gemika/database' if defined?(ActiveRecord)
require 'gemika/matrix'
require 'gemika/rspec' if defined?(RSpec) || defined?(Spec)

# don't load tasks by default
