require 'gemika/errors'
require 'gemika/env'

module Gemika
  module RSpec

    ##
    # Runs the RSpec binary.
    #
    def run_specs(options = nil)
      options ||= {}
      files = options.fetch(:files, 'spec')
      rspec_options = options.fetch(:options, '--color')
      # We need to override the gemfile explicitely, since we have a default Gemfile in the project root
      gemfile = options.fetch(:gemfile, Gemika::Env.gemfile)
      fatal = options.fetch(:fatal, true)
      runner = binary(:gemfile => gemfile)
      command = "bundle exec #{runner} #{rspec_options} #{files}"
      result = shell_out(command)
      if result
        true
      elsif fatal
        raise RSpecFailed, "RSpec failed: #{command}"
      else
        false
      end
    end

    ##
    # Returns the binary name for the current RSpec version.
    #
    def binary(options = {})
      if Env.gem?('rspec', '< 2', options)
        'spec'
      else
        'rspec'
      end
    end

    ##
    # Configures RSpec.
    #
    # Works with both RSpec 1 and RSpec 2.
    #
    def configure(&block)
      configurator.configure(&block)
    end

    ##
    # Configures RSpec to clean out the database before each example.
    #
    # Requires the `database_cleaner` gem to be added to your development dependencies.
    #
    def configure_clean_database_before_example
      require 'database_cleaner' # optional dependency
      configure do |config|
        config.before(:each) do
          # Truncation works across most database adapters; I had issues with :deletion and pg
          DatabaseCleaner.clean_with(:truncation)
        end
      end
    end

    ##
    # Configures RSpec so it allows the `should` syntax that works across all RSpec versions.
    #
    def configure_should_syntax
      if Env.gem?('rspec', '>= 2.11')
        configure do |config|
          config.expect_with(:rspec) { |c| c.syntax = [:should, :expect] }
          config.mock_with(:rspec) { |c| c.syntax = [:should, :expect] }
        end
      else
        # We have an old RSpec that only understands should syntax
      end
    end

    private

    def shell_out(command)
      system(command)
    end

    def configurator
      if Env.gem?('rspec', '<2')
        Spec::Runner
      else
        ::RSpec
      end
    end

    extend self

  end
end
