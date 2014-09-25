namespace :post do
  def formatted_title(title)
    "#{Time.new.strftime('%Y-%m-%d')}-#{title.gsub(' ', '-')}.html.markdown"
  end

  def content(title)
    [
      "---",
      "title: #{title}",
      "date: #{Time.new.strftime('%Y/%m/%d')}",
      "tags:",
      "thumbnail: default_thumb.png",
      "teaser:",
      "published: false",
      "---"
    ].join("\n")
  end

  task :new, [:title] do |task, args|
    title = args[:title]

    File.open("source/blog/#{formatted_title(title)}", 'w+') { |file| file.write(content(title)) }
  end
end
