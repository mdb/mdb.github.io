require 'spec_helper'

describe "posts/_form.html.erb" do

  before :each do
    @post = Post.create :title => 'foo'
    render :template => "posts/_form"
  end

  it "renders a form element" do
    rendered.should have_selector 'form'
  end

  it "renders a form with a tags field" do
    rendered.should have_selector 'label', :text => 'Tags (separated by commas)'
  end

  it "renders a form with an 'Active' field" do
    rendered.should have_selector 'label', :text => 'Active'
  end

  it "renders a form with a 'Thumbnail' field" do
    rendered.should have_selector 'label', :text => 'Thumbnail'
    rendered.should have_selector 'input#post_thumbnail'
  end
end
