require 'yaml'
require 'gemika/errors'
require 'gemika/env'
require 'gemika/matrix/travis_config'
require 'gemika/matrix/github_actions_config'

module Gemika
  class Matrix

    ##
    # A row in the test matrix
    #
    class Row

      def initialize(attrs)
        @ruby = attrs.fetch(:ruby)
        @gemfile = attrs.fetch(:gemfile)
      end

      ##
      # The Ruby version for the row.
      #
      attr_reader :ruby

      ##
      # The path to the gemfile for the row.
      #
      attr_reader :gemfile

      ##
      # Returns whether this row can be run with the given Ruby version.
      #
      def compatible_with_ruby?(current_ruby = Env.ruby)
        ruby == current_ruby
      end

      ##
      # Raises an error if this row is invalid.
      #
      # @!visibility private
      #
      def validate!
        File.exists?(gemfile) or raise MissingGemfile, "Gemfile not found: #{gemfile}"
        contents = File.read(gemfile)
        contents.include?('gemika') or raise UnusableGemfile, "Gemfile is missing gemika dependency: #{gemfile}"
      end

    end

    COLOR_HEAD = "\e[44;97m"
    COLOR_WARNING = "\e[33m"
    COLOR_SUCCESS = "\e[32m"
    COLOR_FAILURE = "\e[31m"
    COLOR_RESET = "\e[0m"

    def initialize(options)
      @rows = options.fetch(:rows)
      @silent = options.fetch(:silent, false)
      @io = options.fetch(:io, STDOUT)
      @color = options.fetch(:color, true)
      validate = options.fetch(:validate, true)
      @rows.each(&:validate!) if validate
      @results = Env.new_ordered_hash
      @compatible_count = 0
      @all_passed = nil
      @current_ruby = options.fetch(:current_ruby, RUBY_VERSION)
    end

    ##
    # Runs the given `block` for each matrix row that is compatible with the current Ruby.
    #
    # The row's gemfile will be set as an environment variable, so Bundler will use that gemfile if you shell out in `block`.
    #
    # At the end it will print a summary of which rows have passed, failed or were skipped (due to incompatible Ruby version).
    #
    def each(&block)
      @all_passed = true
      rows.each do |row|
        gemfile = row.gemfile
        if row.compatible_with_ruby?(current_ruby)
          @compatible_count += 1
          print_title gemfile
          gemfile_passed = Env.with_gemfile(gemfile, row, &block)
          @all_passed &= gemfile_passed
          if gemfile_passed
            @results[row] = tint('Success', COLOR_SUCCESS)
          else
            @results[row] = tint('Failed', COLOR_FAILURE)
          end
        else
          @results[row] = tint("Skipped", COLOR_WARNING)
        end
      end
      print_summary
    end


    ##
    # Builds a {Matrix} from a `.travis.yml` file, or falls back to a Github Action .yml file
    #
    # @param [Hash] options
    # @option options [String] Path to the `.travis.yml` file.
    #
    def self.from_ci_config
      travis_location = '.travis.yml'
      workflow_location = '.github/workflows/test.yml'
      if File.exists?(travis_location)
        from_travis_yml(:path => travis_location)
      elsif File.exists?(workflow_location)
        from_github_actions_yml(:path => workflow_location)
      else
        raise MissingMatrixDefinition, "expected either a #{travis_location} or a #{workflow_location}"
      end
    end

    ##
    # Builds a {Matrix} from the given `.travis.yml` file.
    #
    # @param [Hash] options
    # @option options [String] Path to the `.travis.yml` file.
    #
    def self.from_travis_yml(options = {})
      rows = TravisConfig.load_rows(options)
      new(options.merge(:rows => rows))
    end

    ##
    # Builds a {Matrix} from the given Github Action workflow definition
    #
    # @param [Hash] options
    # @option options [String] Path to the `.yml` file.
    #
    def self.from_github_actions_yml(options = {})
      rows = GithubActionsConfig.load_rows(options)
      new(options.merge(:rows => rows))
    end

    attr_reader :rows, :current_ruby

    private

    def puts(*args)
      unless @silent
        @io.puts(*args)
      end
    end

    def tint(message, color)
      if @color
        color + message + COLOR_RESET
      else
        message
      end
    end

    def print_title(title)
      puts
      puts tint(title, COLOR_HEAD)
      puts
    end

    def print_summary
      print_title 'Summary'

      gemfile_size = @results.keys.map { |row| row.gemfile.size }.max
      ruby_size = @results.keys.map { |row| row.ruby.size }.max

      @results.each do |entry, result|
        puts "- #{entry.gemfile.ljust(gemfile_size)}  Ruby #{entry.ruby.ljust(ruby_size)}  #{result}"
      end

      puts

      if @compatible_count == 0
        message = "No gemfiles were compatible with Ruby #{RUBY_VERSION}"
        puts tint(message, COLOR_FAILURE)
        puts
        raise UnsupportedRuby, message
      elsif @all_passed
        puts tint("All gemfiles succeeded for Ruby #{RUBY_VERSION}", COLOR_SUCCESS)
        puts
      else
        message = 'Some gemfiles failed'
        puts tint(message, COLOR_FAILURE)
        puts
        raise MatrixFailed, message
      end
    end

  end

end
