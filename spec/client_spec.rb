require 'spec_helper'

describe Client do
  describe '#session_id' do
    it 'returns valid session id' do
      id = Client.new.get_session_id
      expect(id.class).to eq(String)
      expect(id.size).to eq(48)
    end
  end

  describe 'connection error' do
    it 'should raise exception on refusal' do
      c = Client.new('localhost', 65535)
      expect { c.get_session_id }.to raise_exception(Errno::ECONNREFUSED)
    end

    it 'should raise exception on timeout' do
      c = Client.new('localhost', 9091, nil, timeout: 0.00000001)
      expect { c.get_session_id }.to raise_exception(Timeout::Error)
    end
  end
end
