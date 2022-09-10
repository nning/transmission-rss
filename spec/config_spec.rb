require 'spec_helper'

describe TransmissionRSS::Config do
  describe '#load' do
    before do
      @config = TransmissionRSS::Config.instance
      @config.clear # Remove defaults for now.
      @hash = {'a' => 1, 'b' => [2, 3], 'c' => {'d' => 4}}
    end

    it 'should raise on wrong argument' do
      [nil, 1, []].each do |item|
        expect { @config.load(item) }.to raise_exception(ArgumentError)
      end
    end

    it 'should warn on deprecated options' do
      expect(@config.send(:check_deprecated)).to be false

      @config.load(YAML.load("log_target: 1"))
      expect(@config.send(:check_deprecated)).to be true
    end

    it 'should warn on duplicate urls' do
      expect(@config.send(:check_warnings)).to be false

      @config.load(YAML.load("
        feeds:
          - url: http://example.com
          - url: http://example.com
      "))

      expect(@config.send(:check_warnings)).to be true
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
      let(:yaml) { @hash.to_yaml }

      before do
        @path = '/tmp/transmission-rss-config-test.yml'
        File.write(@path, yaml)
        @config.load(@path, watch: false)
      end

      it 'should merge' do
        expect(@config).to eq(@hash)
      end

      after do
        File.delete(@path)
      end

      context 'with aliases' do
        let(:yaml) do
          %q(
            feeds:
            - url: http://example.com
              regexp: &filters
              - ^something
            - url: http://other.com
              regexp: *filters
          )
        end

        it 'should load without error' do
          expect{@config}.not_to raise_error(Psych::BadAlias)
        end
      end
    end
  end
end
