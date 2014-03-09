require 'spec_helper'

describe TransmissionRSS::Config do
  describe '#load' do
    config = TransmissionRSS::Config.instance
    hash = {'a' => 1, 'b' => [2, 3], 'c' => {'d' => 4}}

    it 'should raise on wrong argument' do
      [nil, 1, []].each do |item|
        expect { config.load(item) }.to raise_exception(ArgumentError)
      end
    end

    it 'should merge hash' do
      config.load(hash)
      expect(config).to eq(hash)
    end

    it 'should allow to get values' do
      hash.keys.each do |x|
        expect(config.send(x.to_sym)).to eq(hash[x])
      end
    end

    it 'should allow to set value' do
      config.a = 2
      expect(config.a).to eq(2)
    end

    it 'should be clearable' do
      config.clear
      expect(config).to eq({})
    end

    it 'should merge yaml file' do
      path = '/tmp/transmission-rss-config-test.yml'
      File.write(path, hash.to_yaml)
      config.load(path)
      expect(config).to eq(hash)
      File.delete(path)
    end
  end
end
