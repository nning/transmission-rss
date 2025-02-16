require 'spec_helper'

describe Client do
  let!(:magnet_link) { 'magnet:?xt=urn:btih:a31bf5dacae5b6f7bbe42d916549c8c4f34489de&dn=archlinux-2016.12.01-dual.iso&tr=udp://tracker.archlinux.org:6969&tr=http://tracker.archlinux.org:6969/announce' }
  let!(:http_url) { 'https://nning.io/Sin Tel.torrent' }

  describe '#session_id' do
    it 'returns valid session id' do
      VCR.use_cassette('session_id', MATCH_REQUESTS_ON) do
        id = Client.new.get_session_id
        expect(id.class).to eq(String)
        expect(id.size).to eq(48)
      end
    end

    [[Errno::ECONNREFUSED, 1], [Timeout::Error, 3]].each do |error, n|
      it 'should raise ' + error.to_s do
        c = Client.new
        expect(c).to receive(:http_request).exactly(n).times.and_raise(error)
        expect { c.get_session_id }.to raise_exception(error)
      end
    end
  end

  describe '#add_torrent' do
    it 'adds magnet link' do
      VCR.use_cassette('add_torrent', MATCH_REQUESTS_ON) do
        response = Client.new.add_torrent(magnet_link)
        expect(response.result).to eq('success')
      end
    end

    it 'adds magnet link with download dir option' do
      VCR.use_cassette('add_torrent_download_dir', MATCH_REQUESTS_ON) do
        response = Client.new.add_torrent(magnet_link, :url, download_dir: '/tmp')
        expect(response.result).to eq('success')
      end
    end

    it 'adds magnet link with paused option' do
      VCR.use_cassette('add_torrent_paused', MATCH_REQUESTS_ON) do
        response = Client.new.add_torrent(magnet_link, :url, paused: true)
        expect(response.result).to eq('success')
      end
    end

    it 'adds magnet link using alternative port' do
      VCR.use_cassette('add_torrent_alt_port', MATCH_REQUESTS_ON) do
        response = Client.new({'port' => 8081}).add_torrent(magnet_link)
        expect(response.result).to eq('success')
      end
    end

    it 'adds magnet link with seed ratio' do
      VCR.use_cassette('add_torrent_with_ratio', MATCH_REQUESTS_ON) do
        response = Client.new.add_torrent(magnet_link, :url, seed_ratio_limit: 1)
        expect(response.result).to eq('success')
      end
    end

    it 'adds http URL with special characters' do
      VCR.use_cassette('add_torrent_via_http_with_special_chars', MATCH_REQUESTS_ON) do
        response = Client.new.add_torrent(http_url, :url)
        expect(response.result).to eq('success')
      end

      VCR.use_cassette('add_torrent_via_http_with_special_chars', MATCH_REQUESTS_ON) do
        response = Client.new.add_torrent(URI.escape(http_url), :url)
        expect(response.result).to eq('success')
      end
    end

    it 'should raise TooManyRequests' do
      VCR.use_cassette('add_torrent_too_many_requests', MATCH_REQUESTS_ON) do
        expect { Client.new.add_torrent(magnet_link) }.to raise_exception(Client::TooManyRequests)
      end
    end
  end

  describe '#set_torrent' do
    it 'sets ratio limit' do
      VCR.use_cassette('set_torrent', MATCH_REQUESTS_ON) do
        response = Client.new.set_torrent(18, {
          'seedRatioLimit' => 1,
          'seedRatioMode' => 1
        })

        expect(response.result).to eq('success')
      end
    end
  end
end
