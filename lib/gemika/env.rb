module Gemika
  module Env

    class Error < StandardError; end
    class Unknown < Error; end

    def gemfile
      ENV['BUNDLE_GEMFILE']
    end

    def gemfile=(path)
      ENV['BUNDLE_GEMFILE'] = path
    end

    def with_gemfile(path, *args, &block)
      old_gemfile = gemfile
      self.gemfile = path
      block.call(*args)
    ensure
      self.gemfile = old_gemfile
    end

    def ruby_1_8?
      RUBY_VERSION.start_with?('1.8.')
    end

    def pg?
      gem?('pg')
    end

    def mysql2?
      gem?('mysql2')
    end

    def active_record_2?
      gem?('activerecord', '< 3')
    end

    def active_record_3_plus?
      gem?('activerecord', '>= 3')
    end

    def rspec_1?
      gem?('rspec', '< 2')
    end

    def rspec_2_plus?
      gem?('rspec', '>= 2')
    end

    def rspec_binary
      if rspec_1?
        'spec'
      elsif rspec_2_plus?
        'rspec'
      else
        raise Unknown, 'Unknown rspec version'
      end
    end

    def rspec_1_in_gemfile?(gemfile)
      lockfile = "#{gemfile}.lock"
      contents = File.read(lockfile)
      contents =~ /\brspec \(1\./
    end

    def rspec_binary_for_gemfile(gemfile)
      if rspec_1_in_gemfile?(gemfile)
        'spec'
      else
        'rspec'
      end
    end

    def gem?(name, requirement_string = nil)
      gem = Gem.loaded_specs[name]
      #puts Gem.loaded_specs.keys
      #puts "Gem for #{name}: #{gem.inspect} / #{Gem.loaded_specs.has_key?(name)}"
      if gem
        if requirement_string
          requirement = Gem::Requirement.new(requirement_string)
          version = gem.version
          #puts "requirement: #{requirement.inspect}"
          #puts "version: #{version.inspect}"
          gem_requirement_satisfied_by_version?(requirement, version)
        else
          true
        end
      else
        false
      end
    end

    def travis?
      !!ENV['TRAVIS']
    end

    def new_ordered_hash
      if defined?(ActiveSupport::OrderedHash)
        ActiveSupport::OrderedHash.new
      else
        {}
      end
    end

    private

    def gem_requirement_satisfied_by_version?(requirement, version)
      if Env.ruby_1_8?
        ops = Gem::Requirement::OPS
        requirement.requirements.all? { |op, rv| (ops[op] || ops["="]).call version, rv }
      else
        requirement.satisfied_by?(version)
      end
    end

    extend self
  end
end
