require_relative 'spec_helper'

describe "Testing helpers for email_helper's read_email method" do

  it "should return an array of options given a hash" do
      test_collection = EmailHelper::EmailCollection
      option_hash = {:from => "foo@bar.com",
                     :to => "bar@foo.com",
                     :subject => "Foo Bar"}
      transformed_options = test_collection.options_hash_to_array(option_hash)
      transformed_options.is_a?(Array).should == true
      option_hash.each_with_index do | keyvalue, index |
          key = keyvalue[0]
          value = keyvalue[1]
         transformed_options[index*2].downcase.to_sym.should == key
         transformed_options[index*2].should == key.to_s.upcase
         transformed_options[index*2 + 1].should == value
      end
  end

end