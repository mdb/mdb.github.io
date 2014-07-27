require "spec_helper"

describe 'index', type: :feature do
  before do
    visit '/'
  end

  it "displays the correct title header" do
    expect(page).to have_selector('header h1 a[href="/"]', text: 'Mike Ball')
  end

  context 'the projects gallery it displays' do
    it 'displays the proper section heading' do
      expect(page).to have_selector('h1.divider', text: 'Recent Projects | View all')
    end
  end
end
