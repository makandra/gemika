require 'yaml'
require 'gemika/env'

module Gemika
  class Database

    class Error < StandardError; end
    class UnknownAdapter < Error; end

    def initialize(options = {})
      yaml_config_folder = options.fetch(:config_folder, 'spec/support')
      yaml_config_filename = Env.travis? ? 'database.travis.yml' : 'database.yml'
      yaml_config_path = File.join(yaml_config_folder, yaml_config_filename)
      if File.exists?(yaml_config_path)
        @yaml_config = YAML.load_file(yaml_config_path)
      else
        warn "No database configuration in #{yaml_config_path}, using defaults: #{adapter_config.inspect}"
        @yaml_config = {}
      end
      @connected = false
    end

    def connect
      unless @connected
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

    def adapter_config
      default_config = {}
      default_config['database'] = guess_database_name
      if Env.pg?
        default_config['adapter'] = 'postgresql'
        default_config['username'] = 'postgres' if Env.travis?
        default_config['password'] = ''
        user_config = @yaml_config['postgresql'] || @yaml_config['postgres'] || @yaml_config['pg'] || {}
      elsif Env.mysql2?
        default_config['adapter'] = 'mysql2'
        default_config['username'] = 'travis' if Env.travis?
        default_config['encoding'] = 'utf8'
        user_config = (@yaml_config['mysql'] || @yaml_config['mysql2']) || {}
      else
        raise UnknownAdapter, "Unknown database type. Either 'pg' or 'mysql2' gem should be in your current bundle."
      end
      default_config.merge(user_config)
    end

    def guess_database_name
      project_name = File.basename(Dir.pwd)
      "#{project_name}_test"
    end

    def connection
      ActiveRecord::Base.connection
    end

  end
end
