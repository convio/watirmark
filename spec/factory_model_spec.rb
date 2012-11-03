require_relative 'spec_helper'

describe "model declaration" do
  specify "set a value on instantiation" do
    FactoryLogin = Watirmark::Model.factory do
      keywords :username, :password
    end

    login = FactoryLogin.new(:username => 'username', :password => 'password')
    login.username.should == 'username'
    login.password.should == 'password'
  end
end


describe "model names" do
  before :all do
    @Model1 = Watirmark::Model.factory do
      keywords :middle_name
      defaults do
        middle_name { "#@model_name middle_name".strip }
      end
    end
  end


  specify "can set the models name" do
    m = @Model1.new
    m.model_name = 'my_model'
    m.model_name.should == 'my_model'
  end


  specify "setting the models name changes the defaults" do
    m = @Model1.new
    m.model_name = 'my_model'
    m.middle_name.should =~ /^my_model/
  end

end


describe "parents" do
  before :all do

    FactorySDP = Watirmark::Model.factory do
      keywords :name, :value
      defaults do
        name { parent.name }
      end
    end

    Config = Watirmark::Model.factory do
      keywords :name
      model FactorySDP
      defaults do
        name { 'a' }
      end
    end

    @model = Config.new
  end

  specify "ask for a parent" do
    @model.factory_sdp.parent.should == @model
    @model.factory_sdp.parent.name.should == 'a'
    @model.factory_sdp.name.should == 'a'
  end
end


describe "defaults" do

  before :all do
    @Model2 = Watirmark::Model.factory do
      keywords :first_name, :last_name, :middle_name, :nickname, :id
      defaults do
        first_name { 'my_first_name' }
        last_name { 'my_last_name' }
        middle_name { "#{model_name} middle_name".strip }
        id { uuid }
      end
    end
  end

  specify "should raise error unless a proc is defined" do
    lambda {
      Watirmark::Model.factory do
        keywords :first_name, :last_name, :middle_name, :nickname, :id
        defaults do
          first_name 'my_first_name'
        end
      end
    }.should raise_error ArgumentError
  end

  specify "retrieve a default proc setting" do
    m = @Model2.new
    m.middle_name.should == 'middle_name'
    m.model_name = 'foo'
    m.middle_name.should == 'foo middle_name'
  end

  specify "should be able to override default settings on initialization" do
    FactoryModelWithDefaults = Watirmark::Model.factory do
      keywords :foo, :bar
      defaults do
        foo { "hello from proc" }
      end
    end

    m = FactoryModelWithDefaults.new :foo => 'hello init'
    m.foo.should == 'hello init'
  end

  specify "update a default setting" do
    m = @Model2.new
    m.first_name.should == 'my_first_name'
    m.first_name = 'fred'
    m.first_name.should == 'fred'
  end

  specify "containing proc pointing to another default" do
    FactorySDP2 = Watirmark::Model.factory do
      keywords :name, :sort_name
      defaults do
        name { "name" }
        sort_name { name }
      end
    end

    model = FactorySDP2.new
    model.name.should == 'name'
    model.sort_name.should == 'name'
  end

  specify "retrieve a default setting" do
    @Model2.new.first_name.should == 'my_first_name'
  end
end


describe "children" do
  before :all do
    Camelize = Watirmark::Model.factory do
      keywords :first_name, :last_name
    end

    FactoryLogin2 = Watirmark::Model.factory do
      keywords :username, :password
      defaults do
        username { 'username' }
        password { 'password' }
      end
    end

    FactoryUser = Watirmark::Model.factory do
      keywords :first_name, :last_name
      model FactoryLogin2, Camelize
      defaults do
        first_name { 'my_first_name' }
        last_name { 'my_last_name' }
      end
    end

    FactoryDonor = Watirmark::Model.factory do
      keywords :credit_card
      model FactoryUser
    end

    FactorySDP3 = Watirmark::Model.factory do
      keywords :name, :value
    end

    FactoryConfig = Watirmark::Model.factory do
      keywords :name
    end

  end

  specify "should be able to see the models" do
    model = FactoryUser.new
    model.factory_login2.should be_kind_of Struct
    model.factory_login2.username.should == 'username'
    model.should be_kind_of Struct
  end

  specify "should be able to see nested models" do
    model = FactoryDonor.new
    model.factory_user.factory_login2.should be_kind_of Struct
    model.factory_user.factory_login2.username.should == 'username'
    model.factory_users.first.factory_login2.should be_kind_of Struct
    model.factory_users.first.factory_login2.username.should == 'username'
  end

  specify "multiple models of the same class should form a collection" do
    model = FactoryConfig.new
    model.add_model FactorySDP3.new(:name => 'a', :value => 1)
    model.add_model FactorySDP3.new(:name => 'b', :value => 2)
    model.factory_sdp3.should be_kind_of Struct
    model.factory_sdp3.name.should == 'a'
    model.factory_sdp3s.size.should == 2
    model.factory_sdp3s.first.name.should == 'a'
    model.factory_sdp3s.last.name.should == 'b'
  end

  specify "should raise an exception if the model is not a constant" do
    lambda {
      Config = Watirmark::Model.factory do
        keywords :name
        model :FactorySDP.new
      end
    }.should raise_error
  end

  specify "should always instantiate NEW instances of submodels" do
    class Hash
      def rows_hash
        self
      end
    end

    FactoryItem = Watirmark::Model.factory do
      keywords :name, :sort_name
      defaults do
        name { "name" }
      end
    end
    Container = Watirmark::Model.factory do
      keywords :name, :sort_name
      search_term { name }
      model FactoryItem
    end

    c = Container.new
    c.factory_item.name.should == 'name'
    c.factory_item.name = 'foo'
    c.factory_item.name.should == 'foo'
    d = Container.new
    d.factory_item.name.should_not == 'foo'
  end

  specify "models containing models in modules should not break model_class_name" do
    module Foo
      module Bar
        FactoryLogin = Watirmark::Model::factory do
          keywords :username, :password
          defaults do
            username { 'username' }
            password { 'password' }
          end
        end

        FactoryUser = Watirmark::Model.factory do
          keywords :first_name, :last_name
          model FactoryLogin
          defaults do
            first_name { 'my_first_name' }
            last_name { 'my_last_name' }
          end
        end
      end
    end

    model = Foo::Bar::FactoryUser.new
    model.factory_login.should be_kind_of Struct
    model.factory_login.username.should == 'username'
  end
end


describe "search_term" do
  specify "is a string" do
    FactoryItem3 = Watirmark::Model.factory do
      keywords :name, :sort_name
      search_term { "name" }
      defaults do
        name { "name" }
      end
    end
    model = FactoryItem3.new
    model.search_term.should == 'name'
  end

  specify "matches another default" do

    FactoryItem4 = Watirmark::Model.factory do
      keywords :name, :sort_name
      search_term { name }
      defaults do
        name { "name" }
      end
    end
    model = FactoryItem4.new
    model.search_term.should == 'name'
  end

  specify "is found in a parent" do


    FactoryItem5 = Watirmark::Model.factory do
      keywords :name, :sort_name
    end

    FactoryContainer = Watirmark::Model.factory do
      keywords :name, :sort_name
      search_term { name }
      model FactoryItem
      defaults do
        name { "name" }
      end
    end


    item = FactoryItem5.new
    item.search_term.should be_nil
    container = FactoryContainer.new
    container.search_term.should == 'name'
    container.factory_item.search_term.should == 'name'
  end
end


describe "find" do

  before :all do


    FirstModel = Watirmark::Model.factory do
      keywords :x
    end
    SecondModel = Watirmark::Model.factory do
      keywords :x
    end
    NoAddedModels = Watirmark::Model.factory do
      keywords :x
    end
    SingleModel = Watirmark::Model.factory do
      keywords :x
    end
    MultipleModels = Watirmark::Model.factory do
      keywords :x
    end


    @first_model = FirstModel.new
    @second_model = SecondModel.new

    @no_added_models = NoAddedModels.new

    @single_model = SingleModel.new
    @single_model.add_model @first_model

    @multiple_models = MultipleModels.new
    @multiple_models.add_model @first_model
    @multiple_models.add_model @second_model
  end
  #Edit find to check so it doesn't have to have Watirmark::Model everytime
  specify 'should find itself' do
    @no_added_models.find(NoAddedModels).should == @no_added_models
    @single_model.find(SingleModel).should == @single_model
    @multiple_models.find(MultipleModels).should == @multiple_models
  end

  specify 'should be able to see a sub_model' do
    @single_model.find(FirstModel).should == @first_model
    @multiple_models.find(FirstModel).should == @first_model
    @multiple_models.find(SecondModel).should == @second_model
  end

  specify 'should be return nil when no model is found' do
    @no_added_models.find(FirstModel).should be_nil
    @single_model.find(NoAddedModels).should be_nil
    @multiple_models.find(NoAddedModels).should be_nil
  end
end

describe "methods in Enumerable should not collide with model defaults" do
  it "#zip" do
    module Watirmark
      module Model
        class Person < Base
          def self.inherited(subclass)
            subclass.default.zip { '78732' }
          end
        end
      end
    end
    z = Watirmark::Model::Person.new(:zip)
    z.new.zip.should == "78732"
  end
end

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

    FactoryModelA = Watirmark::Model::factory do
      keywords :first_name, :last_name, :middle_name, :cardnumber
      traits :contact_name, :credit_card
      defaults do
        middle_name { "A" }
      end
    end

    FactoryModelB = Watirmark::Model::factory do
      keywords :first_name, :last_name, :middle_name, :cardnumber
      traits :contact_name, :credit_card
      defaults do
        middle_name { "B" }
      end
    end


  end

  specify "should have different last names" do
    a = FactoryModelA.new
    b = FactoryModelB.new
    a.middle_name.should_not == b.middle_name
  end

  specify "should have same first names" do
    a = FactoryModelA.new
    b = FactoryModelB.new
    a.first_name.should == b.first_name
  end

  specify "should have same last name but with different UUID" do
    a = FactoryModelA.new
    b = FactoryModelB.new
    a.last_name.should include "last"
    b.last_name.should include "last"
    a.last_name.should_not == b.last_name
  end

  specify "should have same credit card number" do
    a = FactoryModelA.new
    b = FactoryModelB.new
    a.cardnumber.should == b.cardnumber
  end
end

describe "Nested Traits" do

  before :all do
    module Watirmark::Model
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
        traits :donor_address
      end
    end

    FactoryModelA2 = Watirmark::Model.factory do
      keywords :first_name, :last_name, :donor_address, :donor_state
      traits :donor_jim
    end

    FactoryModelB2 = Watirmark::Model.factory do
      keywords :first_name, :last_name, :donor_address, :donor_state
      traits :donor_jane
    end

  end

  specify "should have different first and last name" do
    a = FactoryModelA2.new
    b = FactoryModelB2.new
    a.first_name.should_not == b.first_name
    a.last_name.should_not == b.last_name
  end

  specify "should have same address due to same trait" do
    a = FactoryModelA2.new
    b = FactoryModelB2.new
    a.donor_address.should == "123 Sunset St"
    a.donor_state.should == "TX"
    a.donor_address.should == b.donor_address
    a.donor_state.should == b.donor_state
  end
end

describe "Unpack keywords" do
  before :all do
    class Element
      attr_accessor :value
      def initialize(x)
        @value = x
      end
    end

    class ModelAView < Page
      keyword(:first_name) {Element.new :a}
      keyword(:middle_name) {Element.new :b}
      keyword(:last_name) {Element.new :c}
    end

    FactoryModelA3 = Watirmark::Model.factory do
      keywords *ModelAView.keywords
      defaults do
        first_name {"First"}
        middle_name  {"Middle"}
        last_name {"Last #{uuid}"}
      end
    end

  end

  specify "should add unpacked keywords as keywords" do
    a = FactoryModelA3.new
    a.middle_name.should == "Middle"
    a.first_name.should == "First"
    a.last_name.should include "Last"
  end
end










































