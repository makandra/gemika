$: << File.join(File.dirname(__FILE__), "/../../lib" )

require 'active_record'
require 'byebug'
require 'gemika'

ActiveRecord::Base.default_timezone = :local

Dir["#{File.dirname(__FILE__)}/support/*.rb"].sort.each {|f| require f}
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].sort.each {|f| require f}

Gemika::RSpec.configure_transactional_examples

RSpec.configure do |config|

  config.expect_with(:rspec) { |c| c.syntax = [:should, :expect] }

end
