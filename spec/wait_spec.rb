require File.expand_path("../spec_helper", __FILE__)

module Watirmark
  describe Wait do

    def wait(*args)
      Wait.new(*args)
    end

    it 'should wait until the returned value is true' do
      count = 0
      wait(timeout: 1, interval: 0.5).until { (count += 1) > 1}.should be true
    end

    it 'should poll the correct number of times' do
      count = 0
      begin
        wait(timeout: 1, interval: 0.2).until { (count += 1; false)}
      rescue Timeout::Error
      end
      expect(count).to be 5
    end

    it 'should raise a TimeOutError with correct message if the the timer runs out' do
      expect {
        wait(timeout: 0.1, message: 'Correct Message').until { false }
      }.to raise_error(Timeout::Error, 'Correct Message')
    end

  end
end
