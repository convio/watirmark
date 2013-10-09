require_relative 'spec_helper'

describe Watirmark::Actions do
  before :all do
    class ActionView < Page
      private_keyword(:a)
      private_keyword(:b)
    end

    class ActionController < Watirmark::WebPage::Controller
      @view = ActionView

      def create
      end

      def create_until(&block)
      end

      def edit
      end

      def before_all
      end

      def before_each
      end

      def after_each
      end

      def after_all
      end
    end

    class ActionModel < Watirmark::Model::Factory
      keywords :a, :b
      defaults do
        a { 1 }
        b { 2 }
      end
    end
  end

  before :each do
    @controller = ActionController.new(ActionModel.new)
  end

  it 'before and after' do
    @controller.expects(:before_all).once
    @controller.expects(:after_all).once
    @controller.run :create
  end

  it 'before_each and after_each' do
    @controller.expects(:before_each).once
    @controller.expects(:after_each).once
    @controller.run :create
  end

  it 'before_each and after_each with multiple methods passed to run' do
    @controller.expects(:before_each).twice
    @controller.expects(:after_each).twice
    @controller.run :create, :edit
  end

  it 'use hashes instead of models' do
    controller = ActionController.new(a: 1, b: 2)
    controller.expects(:before_each).once
    controller.expects(:after_each).once
    controller.run :create
  end

  it 'records should be processed separately' do
    controller = ActionController.new
    controller.records << {a: 1, b: 2}
    controller.records << {c: 3, d: 4}
    controller.expects(:before_all).once
    controller.expects(:after_all).once
    controller.expects(:before_each).twice
    controller.expects(:after_each).twice
    controller.run :create
  end

  it 'records should be cleared after run' do
    controller = ActionController.new
    controller.records.should == []
    controller.records << {a: 1, b: 2}
    controller.records << {c: 3, d: 4}
    controller.records.should == [{a: 1, b: 2}, {c: 3, d: 4}]
    controller.run :create
    controller.records.should == []
  end

  it 'records can be assigned models' do
    controller = ActionController.new
    controller.records << ModelOpenStruct.new(:a => 1, :b => 2)
    controller.run :create
    controller.model.a.should == 1
    controller.model.b.should == 2
  end

  it 'records should be processed separately when models are given' do
    controller = ActionController.new
    controller.records << ModelOpenStruct.new(:a => 1, :b => 2)
    controller.records << ModelOpenStruct.new(:c => 3, :d => 4)
    controller.run :create
    controller.model.a.should == nil
    controller.model.b.should == nil
    controller.model.c.should == 3
    controller.model.d.should == 4
  end

  it 'run can accept a block for the stop_until methods' do
    @controller.expects(:before_all).once
    @controller.expects(:after_all).once
    @controller.run(:create_until){ eval "true"}
  end

  class Element
    attr_accessor :value

    def wait_until_present
      true
    end
  end

  class ActionCreateView < Page
    keyword(:a) { Element.new }
    keyword(:b) { Element.new }

    def create(*args)
    end

  end

  class ActionCreateController < Watirmark::WebPage::Controller
    @view = ActionCreateView
  end

  class ActionCreateControllerWithOverride < ActionCreateController
    def populate_data
    end
  end

  it 'should not throw an exception if anything is populated' do
    lambda { ActionCreateController.new(:a => 1).create }.should_not raise_error Watirmark::TestError
  end

  it 'should not throw an exception if populate_data is overridden' do
    lambda { ActionCreateControllerWithOverride.new.create }.should_not raise_error Watirmark::TestError
  end
end
