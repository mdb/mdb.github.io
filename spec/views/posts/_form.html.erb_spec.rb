require 'spec_helper'

describe "posts/_form.html.erb" do

  before :each do
    @post = Post.create :title => 'foo'
    render :template => "posts/_form"
  end

  it "renders a form element" do
    rendered.should have_selector 'form'
  end
end
