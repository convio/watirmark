require_relative 'spec_helper'

describe "controllers should be able to detect and use embedded models" do

  before :all do
    class MyView < Page
      keyword(:element) {}
    end
    class CMUser < Watirmark::Model::Factory
      keywords :first_name
    end
    class CMLogin < Watirmark::Model::Factory
      keywords :username
    end
    class CMPassword < Watirmark::Model::Factory
      keywords :password
    end
    @password = CMPassword.new
    @login = CMLogin.new
    @login.add_model @password
    @user = CMUser.new
    @user.add_model @login
  end

  it 'should be able to see itself' do
    controller = Class.new Watirmark::WebPage::Controller do
      @model = CMUser
      @view = MyView
    end
    controller.new(@user).model.should == @user
    controller.new(@user).model.should_not == @login
  end

  it 'should be able to find a nested model on initialization' do
    controller = Class.new Watirmark::WebPage::Controller do
      @model = CMLogin
      @view = MyView
    end
    controller.new(@user).model.should_not == @user
    controller.new(@user).model.should == @login
  end

  it 'should be able to find a deeply nested model on initialization' do
    controller = Class.new Watirmark::WebPage::Controller do
      @model = CMPassword
      @view = MyView
    end
    controller.new(@user).model.should_not == @user
    controller.new(@user).model.should_not == @login
    controller.new(@user).model.should == @password
  end
end
