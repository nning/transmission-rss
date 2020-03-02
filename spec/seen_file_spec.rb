require 'spec_helper'

describe SeenFile do
  A = tmp_path(:a)

  before(:each, :init) do
    @seen_file = SeenFile.new(A)
    @url = 'http://example.com/foo'

    @seen_file.clear!
    @seen_file.add(@url)
  end

  after(:all) do
    FileUtils.rm_rf(File.dirname(A))
  end

  describe '#add', :init do
    it 'saves entry in instance' do
      expect(@seen_file.include?(@url)).to be true
    end

    it 'saves entry over instances' do
      expect(SeenFile.new(A).include?(@url)).to be true
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

  describe '#file_to_array', :init do
    subject { @seen_file.send(:file_to_array, A) }
    let(:hash) { @seen_file.send(:digest, @url) }

    it 'returns array' do
      expect(subject).to be_a Array
    end

    it 'has correct size' do
      expect(subject.empty?).to be false
      expect(subject.size).to eq(1)
    end

    it 'has correct content' do
      expect(subject.include?(hash)).to be true
    end
  end
end
