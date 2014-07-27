require "spec_helper"

describe 'index', type: :feature do
  before do
    visit '/rss.xml'
  end

  it 'displays the correct title' do
    expect(page).to have_selector('title', text: 'Mike Ball')
  end

  it 'displays a description' do
    expect(page).to have_selector('description', text: 'Recent projects, blog, and information')
  end

  context 'the entry it displays for each blog post' do
    it 'displays a title' do
      expect(page).to have_selector('item title', 'Testing Node.js with Mocha, Expect.js, and Nock')
    end

    it 'displays a link' do
      expect(page).to have_selector('item link', '/blog/testing-node-with-mocha-expect-and-nock/')
    end

    it 'displays a description' do
      expect(page).to have_selector('item description')
    end
  end
end
