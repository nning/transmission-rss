require 'spec_helper'

describe Callback do
  class TestDummy
    extend Callback
    callback :test_callback

    attr_accessor :state

    def go!
      test_callback
    end
  end

  describe '#callback' do
    dummy = TestDummy.new
    dummy.test_callback do
      dummy.state = 1
    end
    dummy.go!

    it 'should be called' do
      expect(dummy.state).to eq(1)
    end
  end
end
