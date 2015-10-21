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

  it 'single element hash' do
    @struct.includes?(a: 1).should == true
  end

  it 'return true if hash is nil' do
   expect { @struct.includes?(nil) }.should raise_error
  end

  it 'throw error if hash is not passed' do
    expect { @struct.includes?(Object.new) }.should raise_error
  end
end
