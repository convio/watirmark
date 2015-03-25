require_relative 'spec_helper'

describe Watirmark::Session do
  before :all do
    @html = File.expand_path(File.dirname(__FILE__) + '/html/controller.html')
  end

  before :each do
    Page.browser.goto "file://#{@html}"
  end

  specify 'prevsibling, prev_sibling, and previous_sibling return same element' do
    element = Page.browser.option(:text => 'b')
    prevsibling_el = element.prevsibling
    prev_sibling_el = element.prev_sibling
    previous_sibling_el = element.previous_sibling

    expect(prevsibling_el).to eq(prev_sibling_el)
    expect(prev_sibling_el).to eq(previous_sibling_el)
  end

  specify 'nextsibling and next_sibling return same element' do
    element = Page.browser.option(:text => 'b')
    nextsibling_el = element.nextsibling
    next_sibling_el = element.next_sibling

    expect(nextsibling_el).to eq(next_sibling_el)
  end

  specify 'can get previous sibling object even though sibling does not exist' do
    element = Page.browser.option(:text => 'a')
    sib = element.previous_sibling
    expect(sib.class).to eq(Watir::HTMLElement)
    expect(sib.exists?).to eq(false)
  end

  specify 'can get following sibling object even though sibling does not exist' do
    element = Page.browser.option(:text => 'c')
    sib = element.next_sibling
    expect(sib.class).to eq(Watir::HTMLElement)
    expect(sib.exists?).to eq(false)
  end

  specify 'can get previous sibling object and evaluate it does exist' do
    element = Page.browser.option(:text => 'b')
    sib = element.previous_sibling
    expect(sib.exist?).to eq(true)
    expect(sib.html).to eq('<option value="a">a</option>')
  end

  specify 'can get following sibling object and evaluate it does exist' do
    element = Page.browser.option(:text => 'b')
    sib = element.next_sibling
    expect(sib.exist?).to eq(true)
    expect(sib.html).to eq('<option value="c">c</option>')
  end

end