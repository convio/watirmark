require_relative 'spec_helper'

describe "model declaration" do
  specify "set a value on instantiation" do
    LoginInit = Watirmark::Model::Base.new(:username, :password)
    login = LoginInit.new(:username => 'username', :password => 'password' )
    login.username.should == 'username'
    login.password.should == 'password'
  end
end


describe "model names" do
  before :all do
    @model = Watirmark::Model::Base.new(:middle_name) do
      default.middle_name    {"#@model_name middle_name".strip}
    end
  end


  specify "can set the models name" do
    m = @model.new
    m.model_name = 'my_model'
    m.model_name.should == 'my_model'
  end


  specify "setting the models name changes the defaults" do
    m = @model.new
    m.model_name = 'my_model'
    m.middle_name.should =~ /^my_model/
  end

end


describe "parents" do
  before :all do
    SDP = Watirmark::Model::Base.new(:name, :value) do
      default.name {parent.name}
    end

    ConfigParent = Watirmark::Model::Base.new(:name) do
      default.name {'a'}

      model SDP
    end
    @model = ConfigParent.new
  end

  specify "ask for a parent" do
    @model.sdp.parent.should == @model
    @model.sdp.parent.name.should == 'a'
    @model.sdp.name.should == 'a'
  end
end


describe "defaults" do

  before :all do
    @model = Watirmark::Model::Base.new(:first_name, :last_name, :middle_name, :nickname, :id) do
      default.first_name  {'my_first_name'}
      default.last_name   {'my_last_name'}
      default.middle_name {"#{model_name} middle_name".strip}
      default.id          {uuid}
    end
  end

  specify "should raise error unless a proc is defined" do
    lambda {
      Watirmark::Model::Base.new(:first_name, :last_name, :middle_name, :nickname, :id) do
       default.first_name  'my_first_name'
      end
    }.should raise_error ArgumentError
  end

  specify "retrieve a default proc setting" do
    m = @model.new
    m.middle_name.should == 'middle_name'
    m.model_name = 'foo'
    m.middle_name.should == 'foo middle_name'
  end

  specify "should be able to override default settings on initialization" do
    ModelWithDefaults = Watirmark::Model::Base.new(:foo, :bar) do
      default.foo         {"hello from proc"}
    end

    m = ModelWithDefaults.new  :foo => 'hello init'
    m.foo.should == 'hello init'
  end

  specify "update a default setting" do
    m = @model.new
    m.first_name.should == 'my_first_name'
    m.first_name = 'fred'
    m.first_name.should == 'fred'
  end

  specify "containing proc pointing to another default" do
    SDPProc = Watirmark::Model::Base.new(:name, :sort_name) do
      default.name      {"name"}
      default.sort_name {name}
    end

    model = SDPProc.new
    model.name.should == 'name'
    model.sort_name.should == 'name'
  end

  specify "retrieve a default setting" do
    @model.new.first_name.should == 'my_first_name'
  end
end


describe "children" do
  before :all do
    camelize = Watirmark::Model::Base.new(:first_name, :last_name)

    Login2 = Watirmark::Model::Base.new(:username, :password) do
      default.username  {'username'}
      default.password  {'password'}
    end

    User2 = Watirmark::Model::Base.new(:first_name, :last_name) do
      default.first_name  {'my_first_name'}
      default.last_name   {'my_last_name'}

      model Login2
      model camelize
    end

    Donor2 = Watirmark::Model::Base.new(:credit_card) do
      model User2
    end

    SDP2 = Watirmark::Model::Base.new(:name, :value)

    Config2 = Watirmark::Model::Base.new(:name)
  end

  specify "should be able to see the models" do
    model = User2.new
    model.login2.should be_kind_of Struct
    model.login2.username.should == 'username'
    model.should be_kind_of Struct
  end

  specify "should be able to see nested models" do
    model = Donor2.new
    model.user2.login2.should be_kind_of Struct
    model.user2.login2.username.should == 'username'
    model.user2s.first.login2.should be_kind_of Struct
    model.user2s.first.login2.username.should == 'username'
  end

  specify "multiple models of the same class should form a collection" do
    model = Config2.new
    model.add_model SDP2.new(:name=>'a', :value=>1)
    model.add_model SDP2.new(:name=>'b', :value=>2)
    model.sdp2.should be_kind_of Struct
    model.sdp2.name.should == 'a'
    model.sdp2s.size.should == 2
    model.sdp2s.first.name.should == 'a'
    model.sdp2s.last.name.should == 'b'
  end

  specify "should raise an exception if the model is not a constant" do
    SDP3 = Watirmark::Model::Base.new(:name, :value)

    lambda{
      Watirmark::Model::Base.new(:name) do
        model SDP3.new
      end
    }.should raise_error
  end

  specify "should always instantiate NEW instances of submodels" do
    class Hash
      def rows_hash
        self
      end
    end
    Item2 = Watirmark::Model::Base.new(:name, :sort_name) do
      default.name {"name"}
    end

    Container2 = Watirmark::Model::Base.new(:name, :sort_name) do
      search_term       {name}
      default.name      {"name_container"}
      model Item2
    end

    c = Container2.new
    c.item2.name.should == 'name'
    c.item2.name = 'foo'
    c.item2.name.should == 'foo'
    d = Container2.new
    d.item2.name.should_not == 'foo'
  end

  specify "models containing models in modules should not break model_class_name" do
    module Foo
      module Bar
        Login4 = Watirmark::Model::Base.new(:username, :password) do
          default.username  {'username'}
          default.password  {'password'}
        end

        User4 = Watirmark::Model::Base.new(:first_name, :last_name) do
          default.first_name  {'my_first_name'}
          default.last_name   {'my_last_name'}

          model Login4
        end
      end
    end

    model = Foo::Bar::User4.new
    model.login4.should be_kind_of Struct
    model.login4.username.should == 'username'
  end
end


describe "search_term" do
  specify "is a string" do
    Item = Watirmark::Model::Base.new(:name, :sort_name) do
      search_term       {"name"}
      default.name      {"name"}
    end
    model = Item.new
    model.search_term.should == 'name'
  end

  specify "matches another default" do
    Item3 = Watirmark::Model::Base.new(:name, :sort_name) do
      search_term       {name}
      default.name      {"name"}
    end
    model = Item3.new
    model.search_term.should == 'name'
  end

  specify "is found in a parent" do
    Item4 = Watirmark::Model::Base.new(:name, :sort_name)

    Container4 = Watirmark::Model::Base.new(:name, :sort_name) do
      search_term       {name}
      default.name      {"name"}
      model Item4
    end

    item = Item4.new
    item.search_term.should be_nil
    container = Container4.new
    container.search_term.should == 'name'
    container.item4.search_term.should == 'name'
  end
end


describe "find" do

  before :all do
    FirstModel2 =  Watirmark::Model::Base.new(:x)
    SecondModel2 =  Watirmark::Model::Base.new(:x)
    NoAddedModels2 =  Watirmark::Model::Base.new(:x)
    SingleModel2 = Watirmark::Model::Base.new(:x)
    MultipleModels2 =  Watirmark::Model::Base.new(:x)

    @first_model = FirstModel2.new
    @second_model = SecondModel2.new

    @no_added_models =  NoAddedModels2.new

    @single_model = SingleModel2.new
    @single_model.add_model @first_model

    @multiple_models = MultipleModels2.new
    @multiple_models.add_model @first_model
    @multiple_models.add_model @second_model
  end

  specify 'should find itself' do
    @no_added_models.find(NoAddedModels2).should == @no_added_models
    @single_model.find(SingleModel2).should == @single_model
    @multiple_models.find(MultipleModels2).should == @multiple_models
  end

  specify 'should be able to see a sub_model' do
    @single_model.find(FirstModel2).should == @first_model
    @multiple_models.find(FirstModel2).should == @first_model
    @multiple_models.find(SecondModel2).should == @second_model
  end

  specify 'should be return nil when no model is found' do
    @no_added_models.find(FirstModel2).should be_nil
    @single_model.find(NoAddedModels2).should be_nil
    @multiple_models.find(NoAddedModels2).should be_nil
  end
end

describe "methods in Enumerable should not collide with model defaults" do
  it "#zip" do
    module Watirmark
      module Model
        class Person < Base
          def self.inherited(subclass)
            subclass.default.zip {'78732'}
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
        first_name   {"first"}
        last_name   {"last_#{uuid}"}
      end

      trait :credit_card do
        cardnumber {4111111111111111}
      end
    end

    @model_a = Watirmark::Model::Base.new(:first_name, :last_name, :middle_name, :cardnumber) do
      default.middle_name {"A"}
      traits :contact_name, :credit_card
    end

    @model_b = Watirmark::Model::Base.new(:first_name, :last_name, :middle_name, :cardnumber) do
      default.middle_name {"B"}
      traits :contact_name, :credit_card
    end

  end

  specify "should have different last names" do
    a = @model_a.new
    b = @model_b.new
    a.middle_name.should_not == b.middle_name
  end

  specify "should have same first names" do
      a = @model_a.new
      b = @model_b.new
      a.first_name.should == b.first_name
  end

  specify "should have same last name but with different UUID" do
    a = @model_a.new
    b = @model_b.new
    a.last_name.should include "last"
    b.last_name.should include "last"
    a.last_name.should_not == b.last_name
  end

  specify "should have same credit card number" do
    a = @model_a.new
    b = @model_b.new
    a.cardnumber.should == b.cardnumber
  end
end

describe "Traits within Traits" do

  before :all do
    module Watirmark::Model

      trait :donor_address do
        donor_address {"123 Sunset St"}
        donor_state {"TX"}
      end

      trait :donor_jim do
        first_name {"Jim"}
        last_name {"Smith"}
        traits :donor_address
      end

      trait :donor_jane do
        first_name {"Jane"}
        last_name {"Baker"}
        traits :donor_address
      end

    end

    @model_a = Watirmark::Model::Base.new(:first_name, :last_name, :donor_address, :donor_state) do
      traits :donor_jim
    end

    @model_b = Watirmark::Model::Base.new(:first_name, :last_name, :donor_address, :donor_state) do
      traits :donor_jane
    end

  end

  specify "should have different first and last name" do
    a = @model_a.new
    b = @model_b.new
    a.first_name.should_not == b.first_name
    a.last_name.should_not == b.last_name
  end

  specify "should have same address due to same trait" do
    a = @model_a.new
    b = @model_b.new
    a.donor_address.should == b.donor_address
    a.donor_state.should == b.donor_state
  end

end










































