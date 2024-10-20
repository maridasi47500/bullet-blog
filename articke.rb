require 'nokogiri'
require 'open-uri'
require 'active_record'
require 'sqlite3'

#ActiveRecord::Base.establish_connection(
#  adapter: 'sqlite3',
#  database: 'bulletproofmusician.db'
#)
#
#class Post < ActiveRecord::Base
#  belongs_to :category
#end
#
#class Category < ActiveRecord::Base
#  has_many :posts
#end
#
#ActiveRecord::Schema.define do
#  unless ActiveRecord::Base.connection.tables.include? 'categories'
#    create_table :categories do |table|
#      table.column :name, :string
#    end
#  end
#
#  unless ActiveRecord::Base.connection.tables.include? 'posts'
#    create_table :posts do |table|
#      table.column :category_id, :integer
#      table.column :title, :string
#      table.column :content, :text
#      table.column :thumbnail_url, :string
#      table.column :background_url, :string
#    end
#  end
#end

url = "https://bulletproofmusician.com/blog/"
response = URI.open(url)
parsed_page = Nokogiri::HTML(response)

valid_categories = ["Anxiety", "Confidence", "Conversations", "Courage", "Focus", "Practice", "Resilience", "Tools"]

category_urls = {
  "Conversations" => "https://bulletproofmusician.com/category/conversations/",
  "Anxiety" => "https://bulletproofmusician.com/category/anxiety/",
  "Confidence" => "https://bulletproofmusician.com/category/confidence/",
  "Courage" => "https://bulletproofmusician.com/category/courage/",
  "Focus" => "https://bulletproofmusician.com/category/focus/",
  "Practice" => "https://bulletproofmusician.com/category/practice/",
  "Resilience" => "https://bulletproofmusician.com/category/resilience/",
  "Tools" => "https://bulletproofmusician.com/category/tools/"
}

category_urls = {
  "Conversations" => "https://bulletproofmusician.com/category/conversations/",
  "Anxiety" => "https://bulletproofmusician.com/category/anxiety/",
  "Confidence" => "https://bulletproofmusician.com/category/confidence/",
  "Courage" => "https://bulletproofmusician.com/category/courage/",
  "Focus" => "https://bulletproofmusician.com/category/focus/",
  "Practice" => "https://bulletproofmusician.com/category/practice/",
  "Resilience" => "https://bulletproofmusician.com/category/resilience/",
  "Tools" => "https://bulletproofmusician.com/category/tools/"
}
#
#category_urls.each do |category_name, url|
#  response = URI.open(url)
#  parsed_page = Nokogiri::HTML(response)
#
#  parsed_page.css('.post').each do |post|
#    title = post.css('.entry-title').text.strip
#    content = post.css('.entry-content').text.strip
#    thumbnail_url = post.css('.post-thumbnail img')&.attr('src')&.value
#    background_url = post.css('.post-image-background')&.attr('src')&.value
#
#    category = Category.find_or_create_by(name: category_name)
#    Post.create(
#      category_id: category.id,
#      title: title,
#      content: content,
#      thumbnail_url: thumbnail_url,
#      background_url: background_url
#    )
#
#    # Debugging output
#    puts "Category: #{category_name}"
#    puts "Title: #{title}"
#    puts "Thumbnail URL: #{thumbnail_url}"
#    puts "Background URL: #{background_url}"
#    puts "Content: #{content[0..50]}..."  # Truncate for preview
#    puts "-------------------"
#  end
#end
#



def extract_image_url(element, *attributes)
  if element.nil?
    puts "Element is nil."
    return nil
  end

  attributes.each do |attribute|
    if element&.attr(attribute)
      puts "Extracted image URL: #{element.attr(attribute)}"
      return element.attr(attribute)
    end
  end

  puts "No valid attribute found in element: #{element.inspect}"
  return nil
end


category_urls = {
  "Conversations" => "https://bulletproofmusician.com/category/conversations/",
  "Anxiety" => "https://bulletproofmusician.com/category/anxiety/",
  "Confidence" => "https://bulletproofmusician.com/category/confidence/",
  "Courage" => "https://bulletproofmusician.com/category/courage/",
  "Focus" => "https://bulletproofmusician.com/category/focus/",
  "Practice" => "https://bulletproofmusician.com/category/practice/",
  "Resilience" => "https://bulletproofmusician.com/category/resilience/",
  "Tools" => "https://bulletproofmusician.com/category/tools/"
}
def scrape_show_page(agent, post_url)
  page = agent.get(post_url)
  background_element = page.at('.attachment-full.size-full')
  background_url = extract_image_url(background_element, 'data-src', 'src', 'data-srcset')
  puts "Extracted background URL from show page: #{background_url}" if background_url
  return background_url

end


def scrape_category_page(category_name, url)
  #response = URI.open(url)
  #parsed_page = Nokogiri::HTML(response)
  agent = Mechanize.new
  page = agent.get(url)

  page.search('.post').each do |post|
    title = post.at('.entry-title').text.strip
    begin
      content = post.at('.entry-content')&.text&.strip || "Content not found"
    rescue => e
      puts "Error extracting content: #{e.message}"
      content = "Content extraction error"
    end


    thumbnail_element = post.at('.attachment-medium.size-medium.wp-post-image.sp-no-webp') || post.at('.attachment-medium.size-medium.wp-post-image')
    thumbnail_url = extract_image_url(thumbnail_element, 'data-src', 'src', 'data-srcset', 'data-lazy-src')

    post_url = post.at('.entry-title a')&.attr('href')  # Fix here: no .value needed

    background_url = post_url ? scrape_show_page(agent, post_url) : nil

    if thumbnail_url.nil? || background_url.nil?
      puts "Thumbnail or Background URL not found for post: #{title}"
      
    end
    thumbnail_url= background_url


    category = Category.find_or_create_by(name: category_name)
    Post.create(
      category_id: category.id,
      title: title,
      content: content,
      thumbnail_url: thumbnail_url,
      background_url: background_url
    )

    # Debugging output
    puts "Category: #{category_name}"
    puts "Title: #{title}"
    puts "Thumbnail URL: #{thumbnail_url}"
    puts "Background URL: #{background_url}"
    puts "Content: #{content[0..50]}..."  # Truncate for preview
    puts "-------------------"
  end
end

category_urls.each do |category_name, base_url|
  # Scrape the first page
  scrape_category_page(category_name, base_url)

  # Scrape subsequent pages (assuming 10 pages for demonstration)
  (2..10).each do |page_number|
    paginated_url = "#{base_url}page/#{page_number}/"
    scrape_category_page(category_name, paginated_url)
  end
end

puts "Scraping completed and data stored successfully!"

