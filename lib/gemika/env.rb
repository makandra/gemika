require 'rubygems'
require 'gemika/errors'

module Gemika
  ##
  # Version switches to write code that works with different versions of
  # Ruby and gem dependencies.
  #
  module Env

    VERSION_PATTERN = /(?:\d+\.)*\d+/

    ##
    # Returns the path to the gemfile for the current Ruby process.
    #
    def gemfile
      if @gemfile_changed
        @process_gemfile
      else
        ENV['BUNDLE_GEMFILE']
      end
    end

    ##
    # Changes the gemfile to the given `path`, runs the given `block`, then resets
    # the gemfile to its original path.
    #
    # @example
    #   Gemika::Env.with_gemfile('gemfiles/Gemfile.rails3') do
    #     system('rspec spec') or raise 'RSpec failed'
    #   end
    #
    def with_gemfile(path, *args, &block)
      # Make sure that if block calls  #gemfile we still return the gemfile for this
      # process, regardless of what's in ENV temporarily
      @gemfile_changed = true
      @process_gemfile = ENV['BUNDLE_GEMFILE']
      Bundler.with_clean_env do
        ENV['BUNDLE_GEMFILE'] = path
        block.call(*args)
      end
    ensure
      @gemfile_changed = false
      ENV['BUNDLE_GEMFILE'] = @process_gemfile
    end

    ##
    # Check if the given gem was activated by the current gemfile.
    # It might or might not have been `require`d yet.
    #
    # @example
    #   Gemika::Env.gem?('activerecord')
    #   Gemika::Env.gem?('activerecord', '= 5.0.0')
    #   Gemika::Env.gem?('activerecord', '~> 4.2.0')
    #
    def gem?(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      name, requirement_string = args
      if options[:gemfile] && !process_gemfile?(options[:gemfile])
        gem_in_gemfile?(options[:gemfile], name, requirement_string)
      else
        gem_activated?(name, requirement_string)
      end
    end

    ##
    # Returns the current version of Ruby.
    #
    def ruby
      RUBY_VERSION
    end

    ##
    # Check if the current version of Ruby satisfies the given requirements.
    #
    # @example
    #   Gemika::Env.ruby?('>= 2.1.0')
    #
    def ruby?(requirement)
      requirement_satisfied?(requirement, ruby)
    end

    ##
    # Returns whether this process is running within a TravisCI build.
    #
    def travis?
      !!ENV['TRAVIS']
    end

    ##
    # Creates an hash that enumerates entries in order of insertion.
    #
    # @!visibility private
    #
    def new_ordered_hash
      # We use it when ActiveSupport is activated
      if ruby?('>= 1.9')
        {}
      elsif gem?('activesupport')
        require 'active_support/ordered_hash'
        ActiveSupport::OrderedHash.new
      else
        # We give up
        {}
      end
    end

    private

    def bundler?
      !gemfile.nil? && gemfile != ''
    end

    def process_gemfile?(given_gemfile)
      bundler? && File.expand_path(gemfile) == File.expand_path(given_gemfile)
    end

    def gem_activated?(name, requirement)
      gem = Gem.loaded_specs[name]
      if gem
        if requirement
          version = gem.version
          requirement_satisfied?(requirement, version)
        else
          true
        end
      else
        false
      end
    end

    def gem_in_gemfile?(gemfile, name, requirement = nil)
      lockfile = lockfile_contents(gemfile)
      if lockfile =~ /\b#{Regexp.escape(name)}\s*\((#{VERSION_PATTERN})\)/
        version = $1
        if requirement
          requirement_satisfied?(requirement, version)
        else
          true
        end
      else
        false
      end
    end

    def requirement_satisfied?(requirement, version)
      requirement = Gem::Requirement.new(requirement) if requirement.is_a?(String)
      version = Gem::Version.new(version) if version.is_a?(String)
      if requirement.respond_to?(:satisfied_by?) # Ruby 1.9.3+
        requirement.satisfied_by?(version)
      else
        ops = Gem::Requirement::OPS
        requirement.requirements.all? { |op, rv| (ops[op] || ops["="]).call version, rv }
      end
    end

    def lockfile_contents(gemfile)
      lockfile = "#{gemfile}.lock"
      File.exists?(lockfile) or raise MissingLockfile, "Lockfile not found: #{lockfile}"
      File.read(lockfile)
    end

    # Make all methods available as static module methods
    extend self

  end
end
