require 'gemika/env'
require 'gemika/matrix'
require 'gemika/rspec'

##
# Rake tasks to run commands for each compatible row in the test matrix.
#
namespace :matrix do

  desc "Run specs for all Ruby #{RUBY_VERSION} gemfiles"
  task :spec, :files do |t, options|
    Gemika::Matrix.from_travis_yml.each do |row|
      options = options.to_hash.merge(
        :gemfile => row.gemfile,
        :fatal => false,
        :bundle_exec => true
      )
      Gemika::RSpec.run_specs(options)
    end
  end

  desc "Install all Ruby #{RUBY_VERSION} gemfiles"
  task :install do
    Gemika::Matrix.from_travis_yml.each do |row|
      system('bundle install')
    end
  end

  desc "List dependencies for all Ruby #{RUBY_VERSION} gemfiles"
  task :list do
    Gemika::Matrix.from_travis_yml.each do |row|
      system('bundle list')
    end
  end

  desc "Update all Ruby #{RUBY_VERSION} gemfiles"
  task :update, :gems do |t, options|
    Gemika::Matrix.from_travis_yml.each do |row|
      system("bundle update #{options[:gems]}")
    end
  end

end
