require 'spec_helper'

describe SeenFile do
  before(:each, :init) do
    @seen_file = SeenFile.new('spec/tmp/a', 'spec/tmp/b')
    @url = 'http://example.com/foo'

    @seen_file.clear!
    @seen_file.add(@url)
  end

  after do
    FileUtils.rm_rf('spec/tmp')
  end

  describe '#add', :init do
    it 'saves entry in instance' do
      expect(@seen_file.include?(@url)).to be true
    end

    it 'saves entry over instances' do
      expect(SeenFile.new.include?(@url)).to be true
    end
  end

  describe '#clear', :init do
    it 'removes all entries' do
      @seen_file.clear!

      expect(@seen_file.size).to eq(0)
      expect(@seen_file.include?(@url)).to be false
    end
  end

  describe '#size', :init do
    it 'returns size' do
      expect(@seen_file.size).to eq(1)
    end
  end

  describe '.migrate!' do
    before do
      @seen_file = SeenFile.new('spec/tmp/a', 'spec/tmp/b')
    end

    pending
  end
end
