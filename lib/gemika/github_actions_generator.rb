module Gemika
  class GithubActionsGenerator
    TYPES = {
      test_sqlite: {
        gemfile_filter: /\.sqlite/,
      },
      test_pg: {
        gemfile_filter: /\.pg/,
        database_setup: [
          'sudo apt-get install -y postgresql-client',
          "PGPASSWORD=postgres psql -c 'create database test;' -U postgres -p 5432 -h localhost",
        ],
        services: {
          'postgres' => {
            'image' => 'postgres',
            'env' => {
              'POSTGRES_PASSWORD' => 'postgres'
            },
            'options' => '--health-cmd pg_isready --health-interval 10s --health-timeout 5s --health-retries 5',
            'ports' => ['5432:5432'],
          },
        },
      },
      test_mysql: {
        gemfile_filter: /\.mysql/,
        database_setup: [
          'sudo apt-get install -y mysql-client libmariadbclient-dev',
          "mysql -e 'create database IF NOT EXISTS test;' -u root --password=password -P 3306 -h 127.0.0.1",
        ],
        services: {
          'mysql' => {
            'image' => 'mysql:5.6',
            'env' => {
              'MYSQL_ROOT_PASSWORD' => 'password',
            },
            'options' => '--health-cmd "mysqladmin ping" --health-interval 10s --health-timeout 5s --health-retries 5',
            'ports' => ['3306:3306'],
          },
        },
      },
      test: {
        gemfile_filter: //,
      }
    }

    def initialize(bundler_version:)
      @bundler_version = bundler_version
    end

    def generate(rows)
      rows_by_type = split_rows_by_gemfile(rows)
      jobs = {}
      rows_by_type.each do |type, type_rows|
        jobs[type.to_s] = job_by_type(type, type_rows)
      end
      full_config(jobs)
    end

    private

    def split_rows_by_gemfile(rows)
      rows.group_by do |row|
        TYPES.detect do |type, type_definition|
          row.gemfile =~ type_definition[:gemfile_filter]
        end.first
      end
    end

    def job_by_type(type, rows)
      matrix = full_matrix(rows) || include_matrix(rows)
      type_definition = TYPES[type]

      steps = [{
        'uses' => 'actions/checkout@v2',
      }, {
        'name' => 'Install ruby',
        'uses' => 'ruby/setup-ruby@v1',
        'with' => {'ruby-version' => '${{ matrix.ruby }}'},
      }]

      if (database_setup = type_definition[:database_setup])
        steps << {
          'name' => 'Setup database',
          'run' => database_setup.join("\n") + "\n",
        }
      end

      steps += [{
        'name' => 'Bundle',
        'run' => "gem install bundler:#{@bundler_version}\nbundle install --no-deployment\n",
      }, {
        'name' => 'Run tests',
        'run' => 'bundle exec rspec',
      }]

      job = {}
      job['runs-on'] = 'ubuntu-20.04'
      if (services = type_definition[:services])
        job['services'] = services
      end
      job['strategy'] = {
        'fail-fast' => false,
        'matrix' => matrix,
      }
      job['env'] = {
        'BUNDLE_GEMFILE' => '${{ matrix.gemfile }}',
      }
      job['steps'] = steps

      job
    end

    def full_matrix(rows)
      rubies = rows.map(&:ruby)
      gemfiles = rows.map(&:gemfile)
      if rubies.size * gemfiles.size == rows.size
        {
          'ruby' => rubies,
          'gemfile' => gemfiles,
        }
      end
    end

    def include_matrix(rows)
      {
        'include' => rows.map do |row|
          {
            'ruby' => row.ruby,
            'gemfile' => row.gemfile,
          }
        end,
      }
    end

    def full_config(jobs)
      {
        'name' => 'Tests',
        'on' => {
          'push' => {
            'branches' => ['master'],
          },
          'pull_request' => {
            'branches' => ['master'],
          },
        },
        'jobs' => jobs,
      }
    end
  end
end
