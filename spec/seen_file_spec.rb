require 'spec_helper'

describe SeenFile do
  describe '#add' do
    before do
      @seen_file = SeenFile.new
      @url = 'http://example.com/foo'

      @seen_file.clear!
      @seen_file.add(@url)
    end

    it 'saves entry in instance' do
      expect(@seen_file.include?(@url)).to be true
    end

    it 'removes all entries' do
      @seen_file.clear!

      expect(@seen_file.size).to eq(0)
      expect(@seen_file.include?(@url)).to be false
    end

    it 'returns size' do
      expect(@seen_file.size).to eq(1)
    end

    it 'saves entry over instances' do
      new_instance = SeenFile.new
      expect(new_instance.include?(@url)).to be true
    end
  end
end
