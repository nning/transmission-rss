require 'spec_helper'

describe Callback do
  before do
    class TestDummy
      extend Callback
      callback :test_callback

      attr_accessor :state

      def go!
        test_callback
      end
    end
  end

  describe '#callback' do
    before do
      @dummy = TestDummy.new
      @dummy.test_callback do
        @dummy.state = 1
      end
      @dummy.go!
    end

    it 'should be called' do
      expect(@dummy.state).to eq(1)
    end
  end
end
