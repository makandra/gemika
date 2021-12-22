$: << File.join(File.dirname(__FILE__), "/../../lib" )

require 'active_record'
require 'gemika'
require 'pry'

if Gemika::Env.gem?('activerecord', '>= 7.0')
  ActiveRecord.default_timezone = :local
else
  ActiveRecord::Base.default_timezone = :local
end

Dir["#{File.dirname(__FILE__)}/support/*.rb"].sort.each {|f| require f}
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].sort.each {|f| require f}

Gemika::RSpec.configure_clean_database_before_example
Gemika::RSpec.configure_should_syntax
