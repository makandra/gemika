require 'yaml'

module Gemika
  class Database

    def initialize(options = {})
      config_folder = options.fetch(:config_folder, 'spec/support')
      config_filename = travis? ? 'database.travis.yml' : 'database.yml'
      config_path = File.join(config_folder, config_filename)
      File.exists?(config_path) or raise ArgumentError, "Missing database configuration file: #{database_config_file}"
      @config = YAML.load_file(config_path)
      @connected = false
    end

    def connect
      unless @connected
        if pg?
          adapter_config = (@config['postgresql'] || @config['postgres'] || @config['pg']).merge(adapter: 'postgresql')
        elsif mysql2?
          adapter_config = (@config['mysql'] || @config['mysql2']).merge(adapter: 'mysql2', encoding: 'utf8')
        else
          raise "Unknown database type"
        end
        ActiveRecord::Base.establish_connection(adapter_config)
        @connected = true
      end
    end

    def drop_tables!
      connect
      connection.tables.each do |table|
        connection.drop_table table
      end
    end

    def migrate(&block)
      connect
      ActiveRecord::Migration.class_eval(&block)
    end

    def rewrite_schema!(&block)
      connect
      drop_tables!
      migrate(&block)
    end

    private

    def connection
      ActiveRecord::Base.connection
    end

    def pg?
      not mysql2?
    end

    def mysql2?
      gemfile_contents =~ /\bmysql2\b/
    end

    def travis?
      !!ENV['TRAVIS']
    end

    def gemfile_contents
      File.read(ENV['BUNDLE_GEMFILE'])
    end

  end
end
