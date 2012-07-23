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
    @model = Watirmark::Model::Simple.new(:first_name, :last_name, :middle_name, :nickname) do
      default.first_name  'my_first_name'
      default.last_name   'my_last_name'
      default.middle_name  {"#{model_name} middle_name".strip}
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


  specify "update a default setting" do
    m = @model.new
    m.first_name = 'fred'
    m.first_name.should == 'fred'
  end
end
                   # add test her

describe "composed fields" do
  before :all do
    @model = Watirmark::Model::Simple.new(:first_name, :last_name, :middle_name, :nickname) do
      default.first_name  'my_first_name'
      default.last_name   'my_last_name'
      default.middle_name  {"#{model_name} middle_name".strip}

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
end


describe "should inherit defaults" do
  specify "test" do
    User = Watirmark::Model::Person.new(:user_name, :password)
    @login = User.new
    @login.user_name.should =~ /user_/
    @login.password.should == 'password'
  end

end

describe "instance values" do
  before :all do
    Login = Watirmark::Model::Simple.new(:user_name, :password)
  end


  specify "set a value on instantiation" do
    @login = Login.new(:user_name => 'user_name', :password => 'password' )
    @login.user_name.should == 'user_name'
    @login.password.should == 'password'
  end

end

describe "models containing models" do
  before :all do
    Login = Watirmark::Model::Simple.new(:user_name, :password) do
      default.user_name  'user_name'
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
    @model.login.user_name.should == 'user_name'
  end

  specify "should be able to see the models multiple steps down" do
    @model = Donor.new
    @model.user.login.should be_kind_of Struct
    @model.user.login.user_name.should == 'user_name'
  end

end