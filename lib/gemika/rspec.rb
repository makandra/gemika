module Gemika
  class RSpec
    class << self

      def configure_transactional_examples
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
