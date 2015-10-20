require_relative 'spec_helper'

describe "ModelOpenStruct includes?" do
  before :all do
    @struct = ModelOpenStruct.new(a: 1, b: 2, c: 'three')
  end

  it 'open struct includes hash' do
    @struct.includes?(a: 1, c: 'three').should == true
  end

  it 'open struct does not include hash' do
    @struct.includes?(d: 1).should == false
  end
end
