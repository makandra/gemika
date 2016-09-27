require 'yaml'

module Gemika
  class Matrix

    class Error < StandardError; end
    class Invalid < Error; end
    class Failed < Error; end
    class Incompatible < Error; end

    class TravisConfig
      class << self

        def load_rows(options)
          path = options.fetch(:path, '.travis.yml')
          travis_yml = YAML.load_file(path)
          rubies = travis_yml.fetch('rvm')
          gemfiles = travis_yml.fetch('gemfile')
          matrix_options = travis_yml.fetch('matrix', {})
          excludes = matrix_options.fetch('exclude', [])
          rows = []
          rubies.each do |ruby|
            gemfiles.each do |gemfile|
              row = { 'rvm' => ruby, 'gemfile' => gemfile }
              rows << row unless excludes.include?(row)
            end
          end
          rows = rows.map { |row| convert_row(row) }
          rows
        end

        def convert_row(travis_row)
          Row.new(ruby: travis_row['rvm'], gemfile: travis_row['gemfile'])
        end

      end
    end

    class Row

      def initialize(attrs)
        @ruby = attrs.fetch(:ruby)
        @gemfile = attrs.fetch(:gemfile)
      end

      attr_reader :ruby, :gemfile

      def compatible_with_ruby?(current_ruby)
        ruby == current_ruby
      end

      def validate!
        File.exists?(gemfile) or raise Invalid, "Gemfile not found: #{gemfile}"
        contents = File.read(gemfile)
        contents.include?('gemika') or raise Invalid, "Gemfile is missing gemika dependency: #{gemfile}"
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
      @results = {}
      @compatible_count = 0
      @all_passed = nil
      @current_ruby = options.fetch(:current_ruby, RUBY_VERSION)
    end

    def each(&block)
      @all_passed = true
      rows.each do |row|
        gemfile = row.gemfile
        if row.compatible_with_ruby?(current_ruby)
          @compatible_count += 1
          print_title gemfile
          gemfile_passed = call_block_with_gemfile(block, gemfile)
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

    def self.from_travis_yml(options = {})
      rows = TravisConfig.load_rows(options)
      new(options.merge(:rows => rows))
    end

    attr_reader :rows, :current_ruby

    private

    def puts(*args)
      unless @silent
        @io.puts(*args)
      end
    end

    def call_block_with_gemfile(block, gemfile)
      original_gemfile = ENV['BUNDLE_GEMFILE']
      ENV['BUNDLE_GEMFILE'] = gemfile
      block.call
    ensure
      ENV['BUNDLE_GEMFILE'] = original_gemfile
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
        raise Incompatible, message
      elsif @all_passed
        puts tint("All gemfiles succeeded for Ruby #{RUBY_VERSION}", COLOR_SUCCESS)
        puts
      else
        message = 'Some gemfiles failed'
        puts tint(message, COLOR_FAILURE)
        puts
        raise Failed, message
      end
    end

  end

end
