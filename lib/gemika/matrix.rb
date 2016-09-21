require 'yaml'

module Gemika
  class Matrix

    COLOR_HEAD = "\e[44;97m"
    COLOR_WARNING = "\e[33m"
    COLOR_SUCCESS = "\e[32m"
    COLOR_FAILURE = "\e[31m"
    COLOR_RESET = "\e[0m"

    def initialize(options)
      @rows = options.fetch(:rows)
      @rows.each { |row| validate_row(row) }
      @results = {}
      @all_passed = nil
    end

    def each(&block)
      @all_passed = true
      rows.each do |entry|
        gemfile = entry['gemfile']
        if compatible?(entry)
          print_title gemfile
          ENV['BUNDLE_GEMFILE'] = gemfile
          gemfile_passed = block.call
          @all_passed &= gemfile_passed
          if gemfile_passed
            @results[entry] = tint('Success', COLOR_SUCCESS)
          else
            @results[entry] = tint('Failed', COLOR_FAILURE)
          end
        else
          @results[entry] = tint("Skipped", COLOR_WARNING)
        end
      end
      print_summary
    end

    def self.from_travis_yml
      travis_yml = YAML.load_file('.travis.yml')
      rubies = travis_yml.fetch('rvm')
      gemfiles = travis_yml.fetch('gemfile')
      matrix_options = travis_yml.fetch('matrix', {})
      excludes = matrix_options.fetch('exclude', [])
      includes = matrix_options.fetch('include', [])
      rows = []
      rubies.each do |ruby|
        gemfiles.each do |gemfile|
          row = { 'rvm' => ruby, 'gemfile' => gemfile }
          rows << row unless excludes.include?(row)
        end
      end
      rows += includes
      new(:rows => rows)
    end

    def validate_row(row)
      gemfile = row['gemfile']
      File.exists?(gemfile) or raise ArgumentError, "Gemfile not found: #{gemfile}"
      contents = File.read(gemfile)
      contents.include?('gemika') or raise ArgumentError, "Gemfile is missing gemika dependency: #{gemfile}"
      row
    end

    private

    attr_reader :rows

    def compatible?(entry)
      entry['rvm'] == RUBY_VERSION
    end

    def tint(message, color)
      color + message + COLOR_RESET
    end

    def print_title(title)
      puts
      puts tint(title, COLOR_HEAD)
      puts
    end

    def print_summary
      print_title 'Summary'

      gemfile_size = @results.keys.map { |entry| entry['gemfile'].size }.max
      ruby_size = @results.keys.map { |entry| entry['rvm'].size }.max

      @results.each do |entry, result|
        puts "- #{entry['gemfile'].ljust(gemfile_size)}  Ruby #{entry['rvm'].ljust(ruby_size)}  #{result}"
      end

      puts

      if @all_passed
        puts tint("All gemfiles succeeded for Ruby #{RUBY_VERSION}.", COLOR_SUCCESS)
        puts
      else
        puts tint('Some gemfiles failed.', COLOR_FAILURE)
        puts
        fail
      end
    end

  end

end
