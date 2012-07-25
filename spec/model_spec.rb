require 'spec_helper'
require 'watirmark'

describe "models name" do
  before :all do
    @model = Watirmark::Model::Simple.new(:middle_name) do
      default.middle_name  {"#{model_name} middle_name".strip}
      compose :full_name do
        "#{model_name}foo"
      end
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


  specify "setting the models name changes the composed fields" do
    m = @model.new
    m.model_name = 'my_model'
    m.full_name.should =~ /^my_model/
  end
end


describe "default values" do
  before :all do
    @model = Watirmark::Model::Simple.new(:first_name, :last_name, :middle_name, :nickname, :id) do
      default.first_name  'my_first_name'
      default.last_name   'my_last_name'
      default.middle_name  {"#{model_name} middle_name".strip}
      default.id  "#{uuid}"
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

describe "composed fields" do
  before :all do
    @model = Watirmark::Model::Simple.new(:first_name, :last_name, :middle_name, :nickname) do
      default.first_name  'my_first_name'
      default.last_name   'my_last_name'
      default.middle_name  {"#{model_name}middle_name".strip}

      compose :full_name do
        "#{first_name} #{last_name}"
      end

    end
  end

  specify "set a value that gets used in the composed string" do
    m = @model.new
    m.full_name.should == "my_first_name my_last_name"
    m.first_name = 'coolio'
    m.full_name.should == "coolio my_last_name"
  end

  specify "get a string composed in the default declaration" do
    m = @model.new
    m.model_name = 'foo_'
    m.middle_name.should == "foo_middle_name"
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
    Login = Watirmark::Model::Simple.new(:username, :password)
  end


  specify "set a value on instantiation" do
    @login = Login.new(:username => 'username', :password => 'password' )
    @login.username.should == 'username'
    @login.password.should == 'password'
  end

end


describe "models containing models" do
  before :all do
    Login = Watirmark::Model::Simple.new(:username, :password) do
      default.username  'username'
      default.password  'password'
    end

    User = Watirmark::Model::Simple.new(:first_name, :last_name) do
      default.first_name  'my_first_name'
      default.last_name   'my_last_name'

      add_model Login.new
    end

    Donor = Watirmark::Model::Simple.new(:credit_card) do
      add_model User.new
    end
  end


  specify "should be able to see the models" do
    @model = User.new
    @model.login.should be_kind_of Struct
    @model.login.username.should == 'username'
  end

  specify "should be able to see the models multiple steps down" do
    @model = Donor.new
    @model.user.login.should be_kind_of Struct
    @model.user.login.username.should == 'username'
  end

end


describe "models containing collections of models" do
  before :all do
    SDP = Watirmark::Model::Simple.new(:name, :value)

    Collection = Watirmark::Model::Simple.new(:name) do
      add_model SDP.new(:name=>'a', :value=>1)
      add_model SDP.new(:name=>'b', :value=>2)
    end
  end


  specify "call to singular method will return the first model added" do
    @model = Collection.new
    @model.sdp.should be_kind_of Struct
    @model.sdp.name.should == 'a'
  end

  specify "call to collection should be an enumerable" do
    @model = Collection.new
    @model.sdps.size.should == 2
    @model.sdps.first.name.should == 'a'
    @model.sdps.last.name.should == 'b'
  end

end

# how to contain a bunch of models of the same type. (pluralize and make an enumerable)
   # can I add models on the fly to a model after instantiating it?


