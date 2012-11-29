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

  # this is mostly for legacy :(
  specify "should be able to act like an openstruct" do
    login = FactoryTest::InitializeModel.new
    login.foobar.should be_nil
    login.foobar = 'test'
    login.foobar.should == 'test'
  end
end

describe "#update" do
  before :all do
    module FactoryTest
      class UpdateModel < Watirmark::Model::Factory
        keywords :username, :password
      end
    end
  end

  specify "model update should create methods if not in model" do
    login = FactoryTest::UpdateModel.new
    login.update(:foobar=>1)
    login.foobar.should == 1
    login.foobar = 'test'
    login.foobar.should == 'test'
  end

  specify "model update should remove empty keys" do
    login = FactoryTest::UpdateModel.new
    login.respond_to?(:foobar).should be_false
    login.update(:foobar=>2)
    login.foobar.should == 2
    login.foobar = 'test2'
    login.foobar.should == 'test2'
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
          desc { 'some description' }
        end
      end
    end
  end

  specify "retrieve a default proc setting" do
    m = FactoryTest::DefaultModel.new
    m.middle_name.should == 'middle_name'
    m.model_name = 'foo'
    m.middle_name.should == 'foo middle_name'
  end

  specify "update a default setting" do
    m = FactoryTest::DefaultModel.new
    m.first_name.should == 'my_first_name'
    m.first_name = 'fred'
    m.first_name.should == 'fred'
  end

  specify "retrieve a default setting" do
    FactoryTest::DefaultModel.new.first_name.should == 'my_first_name'
  end

  specify "workaround for desc as a default when run from rake" do
    FactoryTest::DefaultModel.new.desc.should == 'some description'
  end

  specify "override default settings on instantiation" do
    module FactoryTest
      class ModelWithDefaults < Watirmark::Model::Factory
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
    class DefaultReference < Watirmark::Model::Factory
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
      class Test < Watirmark::Model::Factory
        keywords :first_name, :last_name, :middle_name, :nickname, :id
        defaults do
          first_name 'my_first_name'
        end
      end
    end
    FactoryTest::Test.new
  }.should raise_error ArgumentError
end
end


describe "model name" do
  before :all do
    class ModelName < Watirmark::Model::Factory
      keywords :middle_name
      defaults do
        middle_name { "#@model_name middle_name".strip }
      end
    end
  end

  specify "can set the models name" do
    m = ModelName.new
    m.model_name = 'my_model'
    m.model_name.should == 'my_model'
  end

  specify "can set the models at initialize (used by transforms)" do
    m = ModelName.new(:model_name => 'my_model')
    m.model_name.should == 'my_model'
  end

  specify "setting the models name changes the defaults" do
    m = ModelName.new
    m.model_name = 'my_model'
    m.middle_name.should =~ /^my_model/
  end
end


describe "parents" do
  specify "ask for a parent" do
    module FactoryTest
      class ChildModel < Watirmark::Model::Factory
        keywords :name, :value
        defaults do
          name { parent.name }
        end
      end

      class ParentModel < Watirmark::Model::Factory
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
      class Camelize < Watirmark::Model::Factory
        keywords :first_name, :last_name
      end

      class Login < Watirmark::Model::Factory
        keywords :username, :password
        defaults do
          username { 'username' }
          password { 'password' }
        end
      end

      class User < Watirmark::Model::Factory
        keywords :first_name, :last_name
        model Login, Camelize
        defaults do
          first_name { 'my_first_name' }
          last_name { 'my_last_name' }
        end
      end

      class Donor < Watirmark::Model::Factory
        keywords :credit_card
        model User
      end

      class SDP < Watirmark::Model::Factory
        keywords :name, :value
      end

      class Config < Watirmark::Model::Factory
        keywords :name
      end
    end

  end

  specify "should be able to see the models" do
    model = FactoryTest::User.new
    model.login.username.should == 'username'
  end

  specify "should be able to see nested models" do
    model = FactoryTest::Donor.new
    model.user.login.username.should == 'username'
    model.users.first.login.username.should == 'username'
  end

  specify "multiple models of the same class should form a collection" do
    model = FactoryTest::Config.new
    model.add_model FactoryTest::SDP.new(:name => 'a', :value => 1)
    model.add_model FactoryTest::SDP.new(:name => 'b', :value => 2)
    model.sdp.name.should == 'a'
    model.sdps.size.should == 2
    model.sdps.first.name.should == 'a'
    model.sdps.last.name.should == 'b'
  end

  specify "should raise an exception if the model is not a constant" do
    lambda {
      class Test < Watirmark::Model::Factory
        keywords :name
        model :FactorySDP.new
      end
    }.should raise_error
  end

  specify "should always instantiate NEW instances of sub-models" do
    module FactoryTest
      class Item < Watirmark::Model::Factory
        keywords :name, :sort_name
        defaults do
          name { "name" }
        end
      end
      class Container < Watirmark::Model::Factory
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
        class Login < Watirmark::Model::Factory
          keywords :username, :password
          defaults do
            username { 'username' }
            password { 'password' }
          end
        end

        class User < Watirmark::Model::Factory
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
    model.login.username.should == 'username'
  end
end

describe "search_term" do
  specify "is a string" do
    module FactoryTest
      class SearchIsString < Watirmark::Model::Factory
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
      class SearchIsDefault < Watirmark::Model::Factory
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
      class SearchChild < Watirmark::Model::Factory
        keywords :name, :sort_name
      end

      class SearchParent < Watirmark::Model::Factory
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
      class FirstModel < Watirmark::Model::Factory
        keywords :x
      end
      class SecondModel < Watirmark::Model::Factory
        keywords :x
      end
      class NoAddedModels < Watirmark::Model::Factory
        keywords :x
      end
      class SingleModel < Watirmark::Model::Factory
        keywords :x
      end
      class MultipleModels < Watirmark::Model::Factory
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
      class ZipModel < Watirmark::Model::Factory
        keywords :zip
        defaults do
          zip { 78732 }
        end
      end
    end
    FactoryTest::ZipModel.new.zip.should == 78732
  end

  it "#zip not in model" do
    module FactoryTest
      class NoZipModel < Watirmark::Model::Factory
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
        keyword(:first_name)  { Element.new :a }
        keyword(:middle_name) { Element.new :b }
        keyword(:last_name)   { Element.new :c }
      end

      class SomeModel < Watirmark::Model::Factory
        keywords SomeView.keywords
        defaults do
          first_name { "First" }
          middle_name { "Middle" }
          last_name { "Last #{uuid}" }
        end
      end

      class SomeOtherModel < Watirmark::Model::Factory
        keywords SomeView.keywords
        defaults do
          first_name { "First" }
          middle_name { "Middle" }
          last_name { "Last #{uuid}" }
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

  specify "should be able to list keywords for a model" do
    FactoryTest::SomeModel.new.keywords.sort.should == [:first_name, :middle_name, :last_name].sort
  end

end

describe "subclassing" do
  before :all do
    module Watirmark::Model
      trait :some_trait do
        full_name { "full_name" }
      end
    end
    module FactoryTest
      class BaseModel < Watirmark::Model::Factory
        keywords :first_name, :last_name, :full_name
        defaults do
          first_name { 'base_first_name' }
          last_name { 'base_last_name' }
        end
        traits :some_trait
      end

      class SubModel < BaseModel
        defaults do
          first_name { 'sub_first_name' }
          last_name { 'sub_last_name' }
        end
      end

      class NoDefaultModel < BaseModel
      end
    end
  end

  specify "submodel should be able to inherit keywords" do
    FactoryTest::SubModel.new.first_name.should == 'sub_first_name'
  end

  specify "submodel should be able to inherit defaults" do
    FactoryTest::NoDefaultModel.new.first_name.should == 'base_first_name'
  end

  specify "submodel should be able to inherit defaults" do
    FactoryTest::NoDefaultModel.new.full_name.should == 'full_name'
  end
end

