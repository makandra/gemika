require 'spec_helper'

describe Gemika::Env do

  subject { Gemika::Env }

  describe '.gemfile' do

    it 'returns the path to the current gemfile' do
      subject.gemfile.should =~ /Gemfile/
    end

    it 'returns the original gemfile of the process, even within blocks to .with_gemfile' do
      original_gemfile = subject.gemfile
      subject.with_gemfile('Foofile') do
        ENV['BUNDLE_GEMFILE'].should == 'Foofile'
        subject.gemfile.should == original_gemfile
      end
    end

  end

  describe '.with_gemfile' do

    it "changes ENV['BUNDLE_GEMFILE'] for the duration of the given block, then sets it back" do
      original_gemfile = ENV['BUNDLE_GEMFILE']
      subject.with_gemfile('Foofile') do
        ENV['BUNDLE_GEMFILE'].should == 'Foofile'
      end
      ENV['BUNDLE_GEMFILE'].should == original_gemfile
    end

  end

  describe '.gem?' do

    it 'returns whether the given gem was activated by the current gemfile' do
      spec = Gem::Specification.new do |spec|
        spec.name = 'activated-gem'
        spec.version = '1.2.3'
      end
      Gem.should_receive(:loaded_specs).at_least(:once).and_return({ 'activated-gem' => spec})
      subject.gem?('activated-gem').should == true
      subject.gem?('other-gem').should == false
    end

    it 'allows to pass a version constraint' do
      spec = Gem::Specification.new do |spec|
        spec.name = 'activated-gem'
        spec.version = '1.2.3'
      end
      Gem.should_receive(:loaded_specs).at_least(:once).and_return({ 'activated-gem' => spec})
      subject.gem?('activated-gem', '=1.2.3').should == true
      subject.gem?('activated-gem', '=1.2.4').should == false
      subject.gem?('activated-gem', '>= 1').should == true
      subject.gem?('activated-gem', '< 1').should == false
      subject.gem?('activated-gem', '~> 1.2.0').should == true
      subject.gem?('activated-gem', '~> 1.1.0').should == false
    end

    it 'allows to query a gemfile that is not the current gemfile' do
      path = 'spec/fixtures/gemfiles/Gemfile_with_activesupport_5'
      subject.gem?('activesupport', :gemfile => path).should == true
      subject.gem?('activesupport', '>= 5', :gemfile => path).should == true
      subject.gem?('activesupport', '~> 5.0.0', :gemfile => path).should == true
      subject.gem?('activesupport', '< 5', :gemfile => path).should == false
      subject.gem?('consul', :gemfile => path).should == false
      subject.gem?('consul', '>= 0', :gemfile => path).should == false
    end

  end

  describe '.ruby?' do

    it 'returns whether the current Ruby version satisfies the given requirement' do
      subject.should_receive(:ruby).at_least(:once).and_return('2.1.8')
      subject.ruby?('=2.1.8').should == true
      subject.ruby?('=1.9.3').should == false
      subject.ruby?('>= 2').should == true
      subject.ruby?('< 2').should == false
      subject.ruby?('~> 2.1.0').should == true
    end

  end

end
