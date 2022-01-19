require 'spec_helper'

describe Gemika::Matrix::Row do

  let(:subject) { described_class.new(ruby: '3.0.3', gemfile: nil) }

  describe '#compatible_with_ruby?' do
    context 'when no rbenv alias is present' do
      before { expect(subject).to receive(:rbenv_aliases).and_return('') }

      context 'when the requested ruby version is the current ruby version' do
        it 'returns true' do
          expect(subject.compatible_with_ruby?('3.0.3')).to eq(true)
        end
      end

      context 'when the requested ruby version is not the current ruby version' do
        it 'returns false' do
          expect(subject.compatible_with_ruby?('2.5.7')).to eq(false)
        end
      end
    end

    context 'when an rbenv alias is present' do
      context 'when the current ruby version is an rbenv alias of the requested version' do
        before { expect(subject).to receive(:rbenv_aliases).and_return('3.0.3 => 3.0.1') }

        it 'returns true and stores that alias in the @used_ruby variable' do
          expect(subject.compatible_with_ruby?('3.0.1')).to eq(true)
          expect(subject.used_ruby).to eq('3.0.1')
          expect(subject.ruby).to eq('3.0.3')
        end
      end

      context 'when the requested ruby version is not aliased by rbenv' do
        before { expect(subject).to receive(:rbenv_aliases).and_return('3.0.0 => 3.0.1') }

        it 'returns true when the requested ruby version is the current ruby version' do
          expect(subject.compatible_with_ruby?('3.0.3')).to eq(true)
          expect(subject.used_ruby).to eq('3.0.3')
          expect(subject.ruby).to eq('3.0.3')
        end

        it 'returns false when the requested ruby version is not the current ruby version' do
          expect(subject.compatible_with_ruby?('3.0.4')).to eq(false)
          expect(subject.used_ruby).to eq('3.0.3')
          expect(subject.ruby).to eq('3.0.3')
        end
      end
    end

    context 'when multiple rbenv aliases chained result in aliasing the requested ruby version' do
      before { expect(subject).to receive(:rbenv_aliases).and_return("3.0.3 => 3.0.2\n3.0.2 => 3.0.1\n3.0.1 => 3.0.0") }

      it 'returns true' do
        expect(subject.compatible_with_ruby?('3.0.0')).to eq(true)
      end
    end

  end

end
