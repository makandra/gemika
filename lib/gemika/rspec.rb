module Gemika
  class RSpec
    class << self

      def configure_transactional_examples
        if Env.rspec_1?

          Spec::Runner.configure do |config|

            config.before :each do
              # from ActiveRecord::Fixtures#setup_fixtures
              connection = ActiveRecord::Base.connection
              connection.increment_open_transactions
              connection.transaction_joinable = false
              connection.begin_db_transaction
            end

            config.after :each do
              # from ActiveRecord::Fixtures#teardown_fixtures
              connection = ActiveRecord::Base.connection
              if connection.open_transactions != 0
                connection.rollback_db_transaction
                connection.decrement_open_transactions
              end
            end

          end

        else

          ::RSpec.configure do |config|
            config.around do |example|
              if example.metadata.fetch(:transaction, example.metadata.fetch(:rollback, true))
                ActiveRecord::Base.transaction do
                  begin
                    example.run
                  ensure
                    raise ActiveRecord::Rollback
                  end
                end
              else
                example.run
              end
            end
          end

        end
      end

    end
  end
end
