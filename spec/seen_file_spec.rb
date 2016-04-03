require 'spec_helper'

describe SeenFile do
  before do
    @seen_file = SeenFile.new('/tmp/rspec/a', '/tmp/rspec/b')
    @url = 'http://example.com/foo'

    @seen_file.clear!
    @seen_file.add(@url)
  end

  describe '#add' do
    it 'saves entry in instance' do
      expect(@seen_file.include?(@url)).to be true
    end

    it 'saves entry over instances' do
      expect(SeenFile.new.include?(@url)).to be true
    end
  end

  describe '#clear' do
    it 'removes all entries' do
      @seen_file.clear!

      expect(@seen_file.size).to eq(0)
      expect(@seen_file.include?(@url)).to be false
    end
  end

  describe '#size' do
    it 'returns size' do
      expect(@seen_file.size).to eq(1)
    end
  end
end
