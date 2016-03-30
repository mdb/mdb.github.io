require "spec_helper"

describe 'index', type: :feature do
  before do
    visit '/'
  end

  it "displays the correct title header" do
    expect(page).to have_selector('header div a[href="/"]', text: 'Mike Ball')
  end

  context 'the projects gallery it displays' do
    it 'displays the proper section heading' do
      expect(page).to have_selector('h1.divider', text: 'Recent Projects')
    end

    it 'displays the proper gallery markup' do
      expect(page).to have_selector('ul.gallery')
    end

    context 'each gallery item' do
      it 'displays the proper thumbnail link' do
        expect(page).to have_selector('ul.gallery li.item a[href="/projects/hopscotch-coffee/"] img')
      end

      it 'reports project details label' do
        expect(page).to have_selector('ul.gallery li.item div.details small', text: 'Project')
      end

      it 'reports project details heading' do
        expect(page).to have_selector('ul.gallery li.item div.details h2 a[href="/projects/hopscotch-coffee/"]', text: 'Hopscotch Coffee Illustration')
      end

      it 'reports project details tags' do
        expect(page).to have_selector('ul.gallery li.item div.details ul.tags li.first a[href="/projects/tags/illustration"]', text: 'illustration')
      end
    end
  end
end
