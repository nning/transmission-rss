require 'spec_helper'

describe TransmissionRSS::Config do
  describe '#load' do
    before do
      @config = TransmissionRSS::Config.instance
      @hash = {'a' => 1, 'b' => [2, 3], 'c' => {'d' => 4}}
    end

    it 'should raise on wrong argument' do
      [nil, 1, []].each do |item|
        expect { @config.load(item) }.to raise_exception(ArgumentError)
      end
    end

    describe 'hash' do
      before do
        @config.load(@hash)
      end

      it 'should merge' do
        expect(@config).to eq(@hash)
      end

      it 'should get values' do
        @hash.keys.each do |x|
          expect(@config.send(x.to_sym)).to eq(@hash[x])
        end
      end

      it 'should set value' do
        @config.a = 2
        expect(@config.a).to eq(2)
      end

      it 'should clear' do
        @config.clear
        expect(@config).to eq({})
      end
    end

    describe 'yaml' do
      before do
        @path = '/tmp/transmission-rss-config-test.yml'
        File.write(@path, @hash.to_yaml)
        @config.load(@path)
      end

      it 'should merge' do
        expect(@config).to eq(@hash)
      end

      after do
        File.delete(@path)
      end
    end
  end
end
