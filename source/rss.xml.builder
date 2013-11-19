xml.instruct! :xml, :version => '1.0'
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Mike Ball"
    xml.description "Recent projects, blog, and information"
    xml.link "http://mikeball.us"

    blog.articles[0..20].each do |post|
      xml.item do
        xml.title post.title
        xml.link post.url
        xml.description post.body
        xml.pubDate post.date.to_time.rfc822
        xml.guid post.url
      end
    end
  end
end
