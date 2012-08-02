require 'spec_helper'
require 'watirmark'

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


describe "default values" do
  before :all do
    @model = Watirmark::Model::Base.new(:first_name, :last_name, :middle_name, :nickname, :id) do
      default.first_name  {'my_first_name'}
      default.last_name   {'my_last_name'}
      default.middle_name {"#{model_name} middle_name".strip}
      default.id          {uuid}
    end
  end


  specify "retrieve a default setting" do
    @model.new.first_name.should == 'my_first_name'
  end


  specify "retrieve a default proc setting" do
    m = @model.new
    m.middle_name.should == 'middle_name'
    m.model_name = 'foo'
    m.middle_name.should == 'foo middle_name'
  end

  specify "should set a uuid" do
    m = @model.new
    m.id.should_not be_nil
  end

  specify "update a default setting" do
    m = @model.new
    m.first_name = 'fred'
    m.first_name.should == 'fred'
  end
end

describe "Inherited Models" do
  specify "should inherit defaults" do
    User = Watirmark::Model::Person.new(:username, :password, :street1)
    @login = User.new
    @login.username.should =~ /user_/
    @login.password.should == 'password'
    @login.street1.should == '3405 Mulberry Creek Dr'
  end

  specify "should inherit unnamed methods" do
    User = Watirmark::Model::Person.new(:username, :password, :firstname)
    @login = User.new
    @login.firstname.should =~ /first_/
  end

end

describe "instance values" do
  before :all do
    Login = Watirmark::Model::Base.new(:username, :password)
  end


  specify "set a value on instantiation" do
    @login = Login.new(:username => 'username', :password => 'password' )
    @login.username.should == 'username'
    @login.password.should == 'password'
  end

end


describe "creates model methods" do
  before :all do
    CamelCase = Watirmark::Model::Base.new(:first_name, :last_name)

    Login = Watirmark::Model::Base.new(:username, :password) do
      default.username  {'username'}
      default.password  {'password'}
    end

    User = Watirmark::Model::Base.new(:first_name, :last_name) do
      default.first_name  {'my_first_name'}
      default.last_name   {'my_last_name'}

      add_model Login.new
      add_model CamelCase.new
    end

    Donor = Watirmark::Model::Base.new(:credit_card) do
      add_model User.new
    end
  end


  specify "should be able to see the models" do
    @model = User.new
    @model.login.should be_kind_of Struct
    @model.login.username.should == 'username'
    @model.camel_case.should be_kind_of Struct
  end

  specify "should be able to see nested models" do
    @model = Donor.new
    @model.user.login.should be_kind_of Struct
    @model.user.login.username.should == 'username'
  end
end

describe "models containing models in modules should not break model_class_name" do
  before :all do
    module Foo
      module Bar
        Login = Watirmark::Model::Base.new(:username, :password) do
          default.username  {'username'}
          default.password  {'password'}
        end

        User = Watirmark::Model::Base.new(:first_name, :last_name) do
          default.first_name  {'my_first_name'}
          default.last_name   {'my_last_name'}

          add_model Login.new
        end
      end
    end
  end

  specify "should be able to see the sub-models" do
    @model = Foo::Bar::User.new
    @model.login.should be_kind_of Struct
    @model.login.username.should == 'username'
  end
end


describe "models containing collections of models" do
  before :all do
    SDP = Watirmark::Model::Base.new(:name, :value)

    Config = Watirmark::Model::Base.new(:name) do
      add_model SDP.new(:name=>'a', :value=>1)
      add_model SDP.new(:name=>'b', :value=>2)
    end
    @model = Config.new
  end


  specify "call to singular method will return the first model added" do
    @model.sdp.should be_kind_of Struct
    @model.sdp.name.should == 'a'
  end

  specify "call to collection should be an enumerable" do
    @model.sdps.size.should == 2
    @model.sdps.first.name.should == 'a'
    @model.sdps.last.name.should == 'b'
  end

  specify "should be able to add models on the fly" do
    @model.add_model SDP.new(:name=>'c', :value=>3)
    @model.add_model SDP.new(:name=>'d', :value=>4)
    @model.sdps.size.should == 4
    @model.sdps.first.name.should == 'a'
    @model.sdps.last.name.should == 'd'
  end

end

describe "search a model's collection for a given model'" do

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

  it 'should find itself' do
    @no_added_models.find(NoAddedModels).should == @no_added_models
    @single_model.find(SingleModel).should == @single_model
    @multiple_models.find(MultipleModels).should == @multiple_models
  end

  it 'should be able to see a sub_model' do
    @single_model.find(FirstModel).should == @first_model
    @multiple_models.find(FirstModel).should == @first_model
    @multiple_models.find(SecondModel).should == @second_model
  end

  it 'should be return nil when no model is found' do
    @no_added_models.find(FirstModel).should be_nil
    @single_model.find(NoAddedModels).should be_nil
    @multiple_models.find(NoAddedModels).should be_nil
  end
end

describe "parent/child relationships" do
  before :all do
    SDP = Watirmark::Model::Base.new(:name, :value) do
      default.name {parent.name}
    end

    Config = Watirmark::Model::Base.new(:name) do
      default.name {'a'}

      add_model SDP.new
    end
    @model = Config.new
  end


  specify "ask for a parent" do
    @model.sdp.parent.should == @model
    @model.sdp.parent.name.should == 'a'
    @model.sdp.name.should == 'a'
  end

end

describe "defaults referring to other defaults" do

  specify "default matches exactly" do
    SDP = Watirmark::Model::Base.new(:name, :sort_name) do
      default.name      {"name"}
      default.sort_name {name}
    end

    model = SDP.new
    model.name.should == 'name'
    model.sort_name.should == 'name'
  end

end

describe "search term" do

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
      add_model Item.new
    end

    item = Item.new
    item.search_term.should be_nil
    container = Container.new
    container.search_term.should == 'name'
    container.item.search_term.should == 'name'
  end
end
