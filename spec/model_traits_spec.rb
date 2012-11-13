require_relative 'spec_helper'

describe "Traits" do

  before :all do
    module Watirmark::Model
      trait :contact_name do
        first_name { "first" }
        last_name { "last_#{uuid}" }
      end

      trait :credit_card do
        cardnumber { 4111111111111111 }
      end
    end

    module FactoryTest
      TraitsA = Watirmark::Model.factory do
        keywords :first_name, :last_name, :middle_name, :cardnumber
        traits :contact_name, :credit_card
        defaults do
          middle_name { "A" }
        end
      end

      TraitsB = Watirmark::Model::factory do
        keywords :first_name, :last_name, :middle_name, :cardnumber
        traits :contact_name, :credit_card
        defaults do
          middle_name { "B" }
        end
      end

      TraitsC = Watirmark::Model::factory do
        keywords :first_name
        defaults do
          first_name { "C" }
        end
        traits :contact_name, :credit_card
      end

      TraitsD = Watirmark::Model::factory do
        keywords :first_name
        traits :contact_name, :credit_card
        defaults do
          first_name { "D" }
        end
      end
    end
  end

  specify "should have different last names" do
    a = FactoryTest::TraitsA.new
    b = FactoryTest::TraitsB.new
    a.middle_name.should_not == b.middle_name
  end

  specify "should have same first names" do
    a = FactoryTest::TraitsA.new
    b = FactoryTest::TraitsB.new
    a.first_name.should == b.first_name
  end

  specify "should have same last name but with different UUID" do
    a = FactoryTest::TraitsA.new
    b = FactoryTest::TraitsB.new
    a.last_name.should include "last"
    b.last_name.should include "last"
    a.last_name.should_not == b.last_name
  end

  specify "should have same credit card number" do
    a = FactoryTest::TraitsA.new
    b = FactoryTest::TraitsB.new
    a.cardnumber.should == b.cardnumber
  end

  specify "defaults should take precedence over traits" do
    FactoryTest::TraitsC.new.first_name.should == "C"
    FactoryTest::TraitsD.new.first_name.should == "D"
  end
end

describe "Nested Traits" do

  before :all do
    module Watirmark::Model
      trait :credit_card do
        credit_card {4111111111111111}
      end

      trait :donor_address do
        donor_address { "123 Sunset St" }
        donor_state { "TX" }
      end

      trait :donor_jim do
        traits :donor_address
        first_name { "Jim" }
        last_name { "Smith" }
      end

      trait :donor_jane do
        first_name { "Jane" }
        last_name { "Baker" }
        traits :donor_address, :credit_card
      end
    end

    module FactoryTest
      Jim = Watirmark::Model.factory do
        keywords :first_name, :last_name, :donor_address, :donor_state, :credit_card
        traits :donor_jim
      end

      Jane = Watirmark::Model.factory do
        keywords :first_name, :last_name, :donor_address, :donor_state, :credit_card
        traits :donor_jane
      end
    end

  end

  specify "should have different first and last name" do
    jim = FactoryTest::Jim.new
    jane = FactoryTest::Jane.new
    jim.first_name.should_not == jane.first_name
    jim.last_name.should_not == jane.last_name
  end

  specify "should have same address due to same trait" do
    jim = FactoryTest::Jim.new
    jane = FactoryTest::Jane.new
    jim.donor_address.should == "123 Sunset St"
    jim.donor_state.should == "TX"
    jim.donor_address.should == jim.donor_address
    jim.donor_state.should == jim.donor_state
    jane.credit_card.should == 4111111111111111
  end
end

