require_relative 'spec_helper'

describe "factory" do
  before :all do
    module FactoryTest
      class InitializeModel < Watirmark::Model::Factory
        keywords :username, :password
      end
    end
  end

  specify "set a value on instantiation" do
    login = FactoryTest::InitializeModel.new(:username => 'username', :password => 'password')
    login.username.should == 'username'
    login.password.should == 'password'
  end

  specify "set a value after initialized" do
    login = FactoryTest::InitializeModel.new
    login.username.should be_nil
    login.password.should be_nil
    login.username = 'username'
    login.password = 'password'
    login.username.should == 'username'
    login.password.should == 'password'
  end
end

describe "defaults" do
  before :all do
    module FactoryTest
      class DefaultModel < Watirmark::Model::Factory
        keywords :first_name, :last_name, :middle_name, :nickname, :id, :desc
        defaults do
          first_name { 'my_first_name' }
          last_name { 'my_last_name' }
          middle_name { "#{model_name} middle_name".strip }
          id { uuid }
          desc {'some description'}
        end
      end
    end
    @model = FactoryTest::DefaultModel
  end

  specify "retrieve a default proc setting" do
    m = @model.new
    m.middle_name.should == 'middle_name'
    m.model_name = 'foo'
    m.middle_name.should == 'foo middle_name'
  end

  specify "update a default setting" do
    m = @model.new
    m.first_name.should == 'my_first_name'
    m.first_name = 'fred'
    m.first_name.should == 'fred'
  end

  specify "retrieve a default setting" do
    @model.new.first_name.should == 'my_first_name'
  end

  specify "workaround for desc as a default when run from rake" do
    @model.new.desc.should == 'some description'
  end

  specify "override default settings on instantiation" do
    module FactoryTest
      ModelWithDefaults = Watirmark::Model.factory do
        keywords :foo, :bar
        defaults do
          foo { "hello from proc" }
        end
      end
    end

    m = FactoryTest::ModelWithDefaults.new :foo => 'hello init'
    m.foo.should == 'hello init'
  end

  specify "defaults can reference each other" do
    module FactoryTest
      DefaultReference = Watirmark::Model.factory do
        keywords :name, :sort_name
        defaults do
          name { "name" }
          sort_name { name }
        end
      end

      model = DefaultReference.new
      model.name.should == 'name'
      model.sort_name.should == 'name'
    end
  end

  specify "should raise error unless a proc is defined" do
    lambda {
      module FactoryTest
        Watirmark::Model.factory do
          keywords :first_name, :last_name, :middle_name, :nickname, :id
          defaults do
            first_name 'my_first_name'
          end
        end
      end
    }.should raise_error ArgumentError
  end
end



describe "model name" do
  before :all do
    @model = Watirmark::Model.factory do
      keywords :middle_name
      defaults do
        middle_name { "#@model_name middle_name".strip }
      end
    end
  end

  specify "can set the models name" do
    m = @model.new
    m.model_name = 'my_model'
    m.model_name.should == 'my_model'
  end

  specify "can set the models at initialize (used by transforms)" do
    m = @model.new(:model_name => 'my_model')
    m.model_name.should == 'my_model'
  end

  specify "setting the models name changes the defaults" do
    m = @model.new
    m.model_name = 'my_model'
    m.middle_name.should =~ /^my_model/
  end
end


describe "parents" do
  specify "ask for a parent" do
    module FactoryTest
      ChildModel = Watirmark::Model.factory do
        keywords :name, :value
        defaults do
          name { parent.name }
        end
      end

      ParentModel = Watirmark::Model.factory do
        keywords :name
        model ChildModel
        defaults do
          name { 'a' }
        end
      end
    end
    model = FactoryTest::ParentModel.new
    model.child.parent.should == model
    model.child.parent.name.should == 'a'
    model.child.name.should == 'a'
  end
end

describe "children" do
  before :all do
    module FactoryTest
      Camelize = Watirmark::Model.factory do
        keywords :first_name, :last_name
      end

      Login = Watirmark::Model.factory do
        keywords :username, :password
        defaults do
          username { 'username' }
          password { 'password' }
        end
      end

      User = Watirmark::Model.factory do
        keywords :first_name, :last_name
        model Login, Camelize
        defaults do
          first_name { 'my_first_name' }
          last_name { 'my_last_name' }
        end
      end

      Donor = Watirmark::Model.factory do
        keywords :credit_card
        model User
      end

      SDP = Watirmark::Model.factory do
        keywords :name, :value
      end

      Config = Watirmark::Model.factory do
        keywords :name
      end
    end

  end

  specify "should be able to see the models" do
    model = FactoryTest::User.new
    model.login.should be_kind_of Struct
    model.login.username.should == 'username'
    model.should be_kind_of Struct
  end

  specify "should be able to see nested models" do
    model = FactoryTest::Donor.new
    model.user.login.should be_kind_of Struct
    model.user.login.username.should == 'username'
    model.users.first.login.should be_kind_of Struct
    model.users.first.login.username.should == 'username'
  end

  specify "multiple models of the same class should form a collection" do
    model = FactoryTest::Config.new
    model.add_model FactoryTest::SDP.new(:name => 'a', :value => 1)
    model.add_model FactoryTest::SDP.new(:name => 'b', :value => 2)
    model.sdp.should be_kind_of Struct
    model.sdp.name.should == 'a'
    model.sdps.size.should == 2
    model.sdps.first.name.should == 'a'
    model.sdps.last.name.should == 'b'
  end

  specify "should raise an exception if the model is not a constant" do
    lambda {
      @model = Watirmark::Model.factory do
        keywords :name
        model :FactorySDP.new
      end
    }.should raise_error
  end

  specify "should always instantiate NEW instances of sub-models" do
    module FactoryTest
      Item = Watirmark::Model.factory do
        keywords :name, :sort_name
        defaults do
          name { "name" }
        end
      end
      Container = Watirmark::Model.factory do
        keywords :name, :sort_name
        search_term { name }
        model Item
      end
    end
    c = FactoryTest::Container.new
    c.item.name.should == 'name'
    c.item.name = 'foo'
    c.item.name.should == 'foo'
    d = FactoryTest::Container.new
    d.item.name.should_not == 'foo'
  end

  specify "models containing models in modules should not break model_class_name" do
    module Foo
      module Bar
        Login = Watirmark::Model::factory do
          keywords :username, :password
          defaults do
            username { 'username' }
            password { 'password' }
          end
        end

        User = Watirmark::Model.factory do
          keywords :first_name, :last_name
          model Login
          defaults do
            first_name { 'my_first_name' }
            last_name { 'my_last_name' }
          end
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
    module FactoryTest
      SearchIsString = Watirmark::Model.factory do
        keywords :name, :sort_name
        search_term { "name" }
        defaults do
          name { "name" }
        end
      end
    end
    model = FactoryTest::SearchIsString.new
    model.search_term.should == 'name'
  end

  specify "matches another default" do
    module FactoryTest
        SearchIsDefault  = Watirmark::Model.factory do
        keywords :name, :sort_name
        search_term { name }
        defaults do
          name { "name" }
        end
      end
    end
    model = FactoryTest::SearchIsDefault.new
    model.search_term.should == 'name'
  end

  specify "is found in a parent" do
    module FactoryTest
      SearchChild = Watirmark::Model.factory do
        keywords :name, :sort_name
      end

      SearchParent = Watirmark::Model.factory do
        keywords :name, :sort_name
        search_term { name }
        model SearchChild
        defaults do
          name { "name" }
        end
      end
    end
    child = FactoryTest::SearchChild.new
    child.search_term.should be_nil
    parent = FactoryTest::SearchParent.new
    parent.search_term.should == 'name'
    parent.search_child.search_term.should == 'name'
  end
end

describe "find" do
  before :all do
    module FactoryTest
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
    end


    @first_model = FactoryTest::FirstModel.new
    @second_model = FactoryTest::SecondModel.new
    @no_added_models = FactoryTest::NoAddedModels.new
    @single_model = FactoryTest::SingleModel.new
    @single_model.add_model @first_model
    @multiple_models = FactoryTest::MultipleModels.new
    @multiple_models.add_model @first_model
    @multiple_models.add_model @second_model
  end

  specify 'should find itself' do
    @no_added_models.find(FactoryTest::NoAddedModels).should == @no_added_models
    @single_model.find(FactoryTest::SingleModel).should == @single_model
    @multiple_models.find(FactoryTest::MultipleModels).should == @multiple_models
  end

  specify 'should be able to see a sub_model' do
    @single_model.find(FactoryTest::FirstModel).should == @first_model
    @multiple_models.find(FactoryTest::FirstModel).should == @first_model
    @multiple_models.find(FactoryTest::SecondModel).should == @second_model
  end

  specify 'should be return nil when no model is found' do
    @no_added_models.find(FactoryTest::FirstModel).should be_nil
    @single_model.find(FactoryTest::NoAddedModels).should be_nil
    @multiple_models.find(FactoryTest::NoAddedModels).should be_nil
  end
end

describe "methods in Enumerable should not collide with model defaults" do
  it "#zip" do
    module FactoryTest
      ZipModel = Watirmark::Model.factory do
        keywords :zip
        defaults do
          zip {78732}
        end
      end
    end
    FactoryTest::ZipModel.new.zip.should == 78732
  end

  it "#zip not in model" do
    module FactoryTest
      NoZipModel = Watirmark::Model.factory do
        keywords :foo
        defaults do
        end
      end
    end
    FactoryTest::NoZipModel.new.respond_to?(:zip).should_not be_true
  end

end

describe "keywords" do
  before :all do
    module FactoryTest
      class Element
        attr_accessor :value
        def initialize(x)
          @value = x
        end
      end

      class SomeView < Page
        keyword(:first_name)  {Element.new :a}
        keyword(:middle_name) {Element.new :b}
        keyword(:last_name)   {Element.new :c}
      end

      SomeModel = Watirmark::Model.factory do
        keywords *SomeView.keywords
        defaults do
          first_name {"First"}
          middle_name  {"Middle"}
          last_name {"Last #{uuid}"}
        end
      end

      SomeOtherModel = Watirmark::Model.factory do
        keywords SomeView.keywords
        defaults do
          first_name {"First"}
          middle_name  {"Middle"}
          last_name {"Last #{uuid}"}
        end
      end
    end
  end

  specify "should add unpacked keywords as keywords" do
    a = FactoryTest::SomeModel.new
    a.middle_name.should == "Middle"
    a.first_name.should == "First"
    a.last_name.should include "Last"
  end

  specify "keywords can be specified without the asterisk" do
    a = FactoryTest::SomeOtherModel.new
    a.middle_name.should == "Middle"
    a.first_name.should == "First"
    a.last_name.should include "Last"
  end

end










































