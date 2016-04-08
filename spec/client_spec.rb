require 'spec_helper'

describe Client do
  describe '#session_id' do
    it 'returns valid session id' do
      VCR.use_cassette('session_id') do
        id = Client.new.get_session_id
        expect(id.class).to eq(String)
        expect(id.size).to eq(48)
      end
    end

    [[Errno::ECONNREFUSED, 1], [Timeout::Error, 3]].each do |error, n|
      it 'should raise ' + error.to_s do
        c = Client.new
        expect(c).to receive(:http_get).exactly(n).times.and_raise(error)
        expect { c.get_session_id }.to raise_exception(error)
      end
    end
  end
end
