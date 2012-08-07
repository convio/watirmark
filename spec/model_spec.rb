require 'spec_helper'
require 'watirmark'


describe "model declaration" do
  specify "set a value on instantiation" do
    Login = Watirmark::Model::Base.new(:username, :password)
    login = Login.new(:username => 'username', :password => 'password' )
    login.username.should == 'username'
    login.password.should == 'password'
  end
end


describe "model names" do
  before :all do
    @model = Watirmark::Model::Base.new(:middle_name) do
      default.middle_name    {"#{@model_name} middle_name".strip}
    end
  end


  specify "can set the models name" do
    m = @model.new
    m.model_name = 'my_model'
    m.model_name.should == 'my_model'
  end


  specify "setting the models name changes the uuid" do
    m = @model.new
    m.model_name = 'my_model'
    m.uuid.should =~ /^my_model/
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

    Config = Watirmark::Model::Base.new(:name) do
      default.name {'a'}

      model SDP
    end
    @model = Config.new
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

  specify "update a default setting" do
    m = @model.new
    m.first_name = 'fred'
    m.first_name.should == 'fred'
  end

  specify "containing proc pointing to another default" do
    SDP = Watirmark::Model::Base.new(:name, :sort_name) do
      default.name      {"name"}
      default.sort_name {name}
    end

    model = SDP.new
    model.name.should == 'name'
    model.sort_name.should == 'name'
  end

  specify "retrieve a default setting" do
    @model.new.first_name.should == 'my_first_name'
  end
end


describe "children" do
  before :all do
    CamelCase = Watirmark::Model::Base.new(:first_name, :last_name)

    Login = Watirmark::Model::Base.new(:username, :password) do
      default.username  {'username'}
      default.password  {'password'}
    end

    User = Watirmark::Model::Base.new(:first_name, :last_name) do
      default.first_name  {'my_first_name'}
      default.last_name   {'my_last_name'}

      model Login
      model CamelCase
    end

    Donor = Watirmark::Model::Base.new(:credit_card) do
      model User
    end

    SDP = Watirmark::Model::Base.new(:name, :value)

    Config = Watirmark::Model::Base.new(:name)
  end

  specify "should be able to see the models" do
    model = User.new
    model.login.should be_kind_of Struct
    model.login.username.should == 'username'
    model.camel_case.should be_kind_of Struct
  end

  specify "should be able to see nested models" do
    model = Donor.new
    model.user.login.should be_kind_of Struct
    model.user.login.username.should == 'username'
  end

  specify "multiple models of the same class should form a collection" do
    model = Config.new
    model.add_model SDP.new(:name=>'a', :value=>1)
    model.add_model SDP.new(:name=>'b', :value=>2)
    model.sdp.should be_kind_of Struct
    model.sdp.name.should == 'a'
    model.sdps.size.should == 2
    model.sdps.first.name.should == 'a'
    model.sdps.last.name.should == 'b'
  end

  specify "should raise an exception if the model is not a constant" do
    SDP = Watirmark::Model::Base.new(:name, :value)

    lambda{
      Config = Watirmark::Model::Base.new(:name) do
        model SDP.new
      end
    }.should raise_error
  end

  specify "should always instantiate NEW instances of submodels" do
    class Hash
      def rows_hash
        self
      end
    end
    Item = Watirmark::Model::Base.new(:name, :sort_name) do
      default.name {"name"}
    end

    Container = Watirmark::Model::Base.new(:name, :sort_name) do
      search_term       {name}
      default.name      {"name_container"}
      model Item
    end

    c = Container.new
    c.item.name.should == 'name'
    c.item.name = 'foo'
    c.item.name.should == 'foo'
    d = Container.new
    d.item.name.should_not == 'foo'
  end

  specify "models containing models in modules should not break model_class_name" do
    module Foo
      module Bar
        Login = Watirmark::Model::Base.new(:username, :password) do
          default.username  {'username'}
          default.password  {'password'}
        end

        User = Watirmark::Model::Base.new(:first_name, :last_name) do
          default.first_name  {'my_first_name'}
          default.last_name   {'my_last_name'}

          model Login
        end
      end
    end

    model = Foo::Bar::User.new
    model.login.should be_kind_of Struct
    model.login.username.should == 'username'
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
    Item = Watirmark::Model::Base.new(:name, :sort_name) do
      search_term       {name}
      default.name      {"name"}
    end
    model = Item.new
    model.search_term.should == 'name'
  end

  specify "is found in a parent" do
    Item = Watirmark::Model::Base.new(:name, :sort_name)

    Container = Watirmark::Model::Base.new(:name, :sort_name) do
      search_term       {name}
      default.name      {"name"}
      model Item
    end

    item = Item.new
    item.search_term.should be_nil
    container = Container.new
    container.search_term.should == 'name'
    container.item.search_term.should == 'name'
  end
end


describe "find" do

  before :all do
    FirstModel =  Watirmark::Model::Base.new(:x)
    SecondModel =  Watirmark::Model::Base.new(:x)
    NoAddedModels =  Watirmark::Model::Base.new(:x)
    SingleModel = Watirmark::Model::Base.new(:x)
    MultipleModels =  Watirmark::Model::Base.new(:x)

    @first_model = FirstModel.new
    @second_model = SecondModel.new

    @no_added_models =  NoAddedModels.new

    @single_model = SingleModel.new
    @single_model.add_model @first_model

    @multiple_models = MultipleModels.new
    @multiple_models.add_model @first_model
    @multiple_models.add_model @second_model
  end

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
