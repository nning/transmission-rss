require 'spec_helper'

describe Client, '#get_session_id' do
  it 'returns valid session id' do
    id = Client.new.get_session_id
    expect(id).not_to eq('')
    expect(id.size).to eq(48)
  end
end
