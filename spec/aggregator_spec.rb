require 'spec_helper'

describe Aggregator do
  SEEN_FILE = tmp_path(:seen_file)
  FEEDS = [
    Feed.new('https://www.archlinux.org/feeds/releases/')
  ]

  subject do
    Aggregator.new(FEEDS, seen_file: SEEN_FILE)
  end

  after(:all) do
    FileUtils.rm_f(SEEN_FILE)
  end

  describe '#fetch' do
    it 'returns content' do
      VCR.use_cassette('feed_fetch', MATCH_REQUESTS_ON) do
        content = subject.send(:fetch, FEEDS.first)

        expect(content).not_to be_empty
        expect(content.size).to eq(1725)
      end
    end
  end

  describe '#parse' do
    it 'returns content' do
      VCR.use_cassette('feed_fetch', MATCH_REQUESTS_ON) do
        content = subject.send(:parse, subject.send(:fetch, FEEDS.first))

        expect(content.size).to eq(3)

        description_matches = content
          .map(&:title)
          .map { |x| x =~ /^[0-9]{4}\.[0-9]{2}\.[0-9]{2}/ }
          .uniq

        expect(description_matches).to eq([0])

        urls = content.map(&:enclosure).map(&:url)

        urls.each do |url|
          url = URI.parse(url)

          expect(url.scheme).to eq('https')
          expect(url.host).to eq('www.archlinux.org')
          expect(File.basename(url.path)).to match(/\.iso\.torrent$/)
        end
      end
    end
  end

  describe '#process_link' do
    before(:each) do    
      VCR.use_cassette('feed_fetch', MATCH_REQUESTS_ON) do  
        ITEM = subject.send(:parse, subject.send(:fetch, FEEDS.first)).first
      end
    end

    it 'returns enclosure link' do
      content = subject.send(:process_link, FEEDS.first, ITEM)

      url = URI.parse(content)

      expect(url.scheme).to eq('https')
      expect(url.host).to eq('www.archlinux.org')
      expect(File.basename(url.path)).to match(/\.iso\.torrent$/)
    end

    it 'returns link if no enclosure link' do
      ITEM.enclosure = nil
      
      content = subject.send(:process_link, FEEDS.first, ITEM)

      url = URI.parse(content)
      expect(url.scheme).to eq('https')
      expect(url.host).to eq('www.archlinux.org')
      expect(File.basename(url.path)).to match(/2020\.01\.01$/)
    end

    it 'returns nil if no link or enclosure link' do
      ITEM.enclosure = nil
      ITEM.link = nil
      
      content = subject.send(:process_link, FEEDS.first, ITEM)

      expect(content).to be_nil
    end
  end
end
