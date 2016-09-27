require 'spec_helper' # can't move this to .rspec in RSpec 1

describe Gemika::Database do

  it 'connects ActiveRecord to the database in database.yml, then migrates the schema' do
    user = User.create!(:email => 'foo@bar.com')
    database_user = User.first
    user.email.should == database_user.email
  end

  it 'wraps each example in a transaction that is rolled back when the transaction ends' do
    User.count.should == 0
  end

end
