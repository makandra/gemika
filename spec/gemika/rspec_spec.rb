require 'spec_helper'

describe Gemika::RSpec do

  # before(:each) { puts "---", "RSpec example", "---" }

  subject { Gemika::RSpec }

  describe '.binary' do

    it 'returns "spec" for RSpec 1' do
      Gemika::Env.should_receive(:gem?).with('rspec', '< 2', {}).and_return(true)
      subject.binary.should == 'spec'
    end

    it 'returns "rspec" for RSpec 2+' do
      Gemika::Env.should_receive(:gem?).with('rspec', '< 2', {}).and_return(false)
      subject.binary.should == 'rspec'
    end

  end

  describe '.run_specs' do

    it 'shells out to the binary' do
      expected_command = %{bundle exec #{subject.binary} --color spec}
      subject.should_receive(:shell_out).with(expected_command).and_return(true)
      subject.run_specs
    end

    it 'allows to pass a :files option' do
      expected_command = %{bundle exec #{subject.binary} --color spec/foo_spec.rb:23}
      subject.should_receive(:shell_out).with(expected_command).and_return(true)
      subject.run_specs(:files => 'spec/foo_spec.rb:23')
    end

    it 'raises an error if the call returns a non-zero error code' do
      subject.should_receive(:shell_out).with(anything).and_return(false)
      expect { subject.run_specs }.to raise_error(Gemika::RSpecFailed)
    end

  end

end
