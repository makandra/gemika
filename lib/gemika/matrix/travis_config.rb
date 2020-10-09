module Gemika
  class Matrix

    ##
    # Load `.travis.yml` files.
    #
    # @!visibility private
    #
    class TravisConfig
      class << self

        def load_rows(options)
          path = options.fetch(:path, '.travis.yml')
          travis_yml = YAML.load_file(path)
          rubies = travis_yml.fetch('rvm', [])
          gemfiles = travis_yml.fetch('gemfile', [])
          matrix_options = travis_yml.fetch('matrix', {})
          includes = matrix_options.fetch('include', [])
          excludes = matrix_options.fetch('exclude', [])

          rows = []
          rubies.each do |ruby|
            gemfiles.each do |gemfile|
              row = { 'rvm' => ruby, 'gemfile' => gemfile }
              rows << row unless excludes.include?(row)
            end
          end

          rows = rows + includes
          rows = rows.map { |row| convert_row(row) }
          rows
        end

        def convert_row(travis_row)
          Row.new(:ruby => travis_row['rvm'], :gemfile => travis_row['gemfile'])
        end

      end
    end

  end
end
