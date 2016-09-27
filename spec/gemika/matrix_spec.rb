require 'spec_helper' # can't move this to .rspec in RSpec 1

describe Gemika::Matrix do

  before :each do
    @original_bundle_gemfile = ENV['BUNDLE_GEMFILE']
  end

  after :each do
    # Make sure failing tests are not messing out our environment
    ENV['BUNDLE_GEMFILE'] = @original_bundle_gemfile
  end

  describe '#each' do

    it "calls the block with each matrix row, setting ENV['BUNDLE_GEMFILE'] to the respective gemfile" do
      current_ruby = '2.1.8'
      row1 = Gemika::Matrix::Row.new(:ruby => current_ruby, :gemfile => 'gemfiles/Gemfile1')
      row2 = Gemika::Matrix::Row.new(:ruby => current_ruby, :gemfile => 'gemfiles/Gemfile2')
      matrix = Gemika::Matrix.new(:rows =>[row1, row2], :validate => false, :current_ruby => current_ruby, :silent => true)
      spy = double('block')
      spy.should_receive(:observe_gemfile).with('gemfiles/Gemfile1')
      spy.should_receive(:observe_gemfile).with('gemfiles/Gemfile2')
      matrix.each do
        spy.observe_gemfile(ENV['BUNDLE_GEMFILE'])
        true
      end
    end

    it 'only calls the block with rows compatible with the current Ruby' do
      current_ruby = '2.1.8'
      other_ruby = '2.3.1'
      row1 = Gemika::Matrix::Row.new(:ruby => current_ruby, :gemfile => 'gemfiles/Gemfile1')
      row2 = Gemika::Matrix::Row.new(:ruby => other_ruby, :gemfile => 'gemfiles/Gemfile2')
      matrix = Gemika::Matrix.new(:rows =>[row1, row2], :validate => false, :current_ruby => current_ruby, :silent => true)
      spy = double('block')
      spy.should_receive(:observe_gemfile).with('gemfiles/Gemfile1')
      spy.should_not_receive(:observe_gemfile).with('gemfiles/Gemfile2')
      matrix.each do
        spy.observe_gemfile(ENV['BUNDLE_GEMFILE'])
        true
      end
    end

    it "resets ENV['BUNDLE GEMFILE'] to its initial value afterwards" do
      original_env = ENV['BUNDLE_GEMFILE']
      original_env.should be_present
      current_ruby = '2.1.8'
      row = Gemika::Matrix::Row.new(:ruby => current_ruby, :gemfile => 'gemfiles/Gemfile1')
      matrix = Gemika::Matrix.new(:rows =>[row], :validate => false, :current_ruby => current_ruby, :silent => true)
      matrix.each { true }
      ENV['BUNDLE_GEMFILE'].should == original_env
    end

    it 'prints an overview of which gemfiles have passed, which have failed, which were skipped' do
      row1 = Gemika::Matrix::Row.new(:ruby => '2.1.8', :gemfile => 'gemfiles/GemfileAlpha')
      row2 = Gemika::Matrix::Row.new(:ruby => '2.1.8', :gemfile => 'gemfiles/GemfileBeta')
      row3 = Gemika::Matrix::Row.new(:ruby => '2.3.1', :gemfile => 'gemfiles/GemfileAlpha')
      require 'stringio'
      actual_output = ''
      io = StringIO.new(actual_output)
      matrix = Gemika::Matrix.new(:rows =>[row1, row2, row3], :validate => false, :current_ruby => '2.1.8', :io => io, :color => false)
      commands = [
        lambda { io.puts 'Successful output'; true },
        lambda { io.puts 'Failed output'; false },
        lambda { io.puts 'Skipped output'; false  }
      ]
      expect { matrix.each { commands.shift.call } }.to raise_error(Gemika::Matrix::Failed)
      expected_output = <<EOF
gemfiles/GemfileAlpha

Successful output

gemfiles/GemfileBeta

Failed output

Summary

- gemfiles/GemfileAlpha  Ruby 2.1.8  Success
- gemfiles/GemfileBeta   Ruby 2.1.8  Failed
- gemfiles/GemfileAlpha  Ruby 2.3.1  Skipped

Some gemfiles failed
EOF
      actual_output.strip.should == expected_output.strip
    end

    it 'should raise an error if a row failed (returns false)' do
      current_ruby = '2.1.8'
      row = Gemika::Matrix::Row.new(:ruby => current_ruby, :gemfile => 'gemfiles/Gemfile')
      matrix = Gemika::Matrix.new(:rows =>[row], :validate => false, :current_ruby => current_ruby, :silent => true)
      expect { matrix.each { false } }.to raise_error(Gemika::Matrix::Failed, /Some gemfiles failed/i)
    end

    it 'should raise an error if no row if compatible with the current Ruby' do
      current_ruby = '2.1.8'
      other_ruby = '2.3.1'
      row = Gemika::Matrix::Row.new(:ruby => other_ruby, :gemfile => 'gemfiles/Gemfile')
      matrix = Gemika::Matrix.new(:rows =>[row], :validate => false, :current_ruby => current_ruby, :silent => true)
      expect { matrix.each { false } }.to raise_error(Gemika::Matrix::Incompatible, /No gemfiles were compatible/i)
    end

  end

  describe '.from_travis_yml' do

    it 'builds a matrix by combining Ruby versions and gemfiles from a Travis CI configuration file' do
      path = 'spec/fixtures/travis_yml/two_by_two.yml'
      matrix = Gemika::Matrix.from_travis_yml(:path => path, :validate => false)
      matrix.rows.size.should == 4
      matrix.rows[0].ruby.should == '2.1.8'
      matrix.rows[0].gemfile.should == 'gemfiles/Gemfile1'
      matrix.rows[1].ruby.should == '2.1.8'
      matrix.rows[1].gemfile.should == 'gemfiles/Gemfile2'
      matrix.rows[2].ruby.should == '2.3.1'
      matrix.rows[2].gemfile.should == 'gemfiles/Gemfile1'
      matrix.rows[3].ruby.should == '2.3.1'
      matrix.rows[3].gemfile.should == 'gemfiles/Gemfile2'
    end

    it 'allows to exclude rows from the matrix' do
      path = 'spec/fixtures/travis_yml/excludes.yml'
      matrix = Gemika::Matrix.from_travis_yml(:path => path, :validate => false)
      matrix.rows.size.should == 3
      matrix.rows[0].ruby.should == '2.1.8'
      matrix.rows[0].gemfile.should == 'gemfiles/Gemfile2'
      matrix.rows[1].ruby.should == '2.3.1'
      matrix.rows[1].gemfile.should == 'gemfiles/Gemfile1'
      matrix.rows[2].ruby.should == '2.3.1'
      matrix.rows[2].gemfile.should == 'gemfiles/Gemfile2'
    end

    it 'raises an error if a Gemfile does not exist' do
      path = 'spec/fixtures/travis_yml/missing_gemfile.yml'
      expect { Gemika::Matrix.from_travis_yml(:path => path) }.to raise_error(Gemika::Matrix::Invalid, /gemfile not found/i)
    end

    it 'raises an error if a Gemfile does not depend on "gemika"' do
      path = 'spec/fixtures/travis_yml/gemfile_without_gemika.yml'
      expect { Gemika::Matrix.from_travis_yml(:path => path) }.to raise_error(Gemika::Matrix::Invalid, /missing gemika dependency/i)
    end

  end

end
