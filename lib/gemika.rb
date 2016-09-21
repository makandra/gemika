require 'gemika/version'
require 'gemika/database' if defined?(ActiveRecord)
require 'gemika/matrix'
require 'gemika/rspec' if defined?(RSpec)

# don't load tasks by default
