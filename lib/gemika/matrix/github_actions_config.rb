module Gemika
  class Matrix

    ##
    # Load Github Action `.yml` files.
    #
    # @!visibility private
    #
    class GithubActionsConfig
      class << self

        def load_rows(options)
          path = options.fetch(:path, '.github/workflows/test.yml')
          workflow_yml = YAML.load_file(path)

          matrices = workflow_yml.fetch('jobs', {}).values.map do |job|
            job.fetch('strategy', {})['matrix']
          end.reject(&:nil?)

          matrices.map do |matrix|
            matrix_to_rows(matrix)
          end.flatten(1)
        end

        private

        def matrix_to_rows(matrix)
          if (!matrix['ruby'] || !matrix['gemfile']) && (!matrix['include'])
            raise InvalidMatrixDefinition, 'matrix must use the keys "ruby" and "gemfile"'
          end

          rubies = matrix.fetch('ruby', [])
          gemfiles = matrix.fetch('gemfile', [])

          includes = matrix.fetch('include', [])
          excludes = matrix.fetch('exclude', [])

          rows = []
          rubies.each do |ruby|
            gemfiles.each do |gemfile|
              row = { 'ruby' => ruby, 'gemfile' => gemfile }
              rows << row unless excludes.include?(row)
            end
          end

          rows = rows + includes
          rows.map { |row| convert_row(row) }
        end

        def convert_row(row_hash)
          if !row_hash['ruby'] || !row_hash['gemfile']
            raise InvalidMatrixDefinition, 'matrix must use the keys "ruby" and "gemfile"'
          end
          Row.new(:ruby => row_hash['ruby'], :gemfile => row_hash['gemfile'])
        end

      end
    end

  end
end
