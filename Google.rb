require 'nokogiri'
require 'open-uri'
require 'mechanize'
require 'active_record'
require 'selenium-webdriver'
require 'net/http'
require 'uri'

p File.read("assistant.txt")

url = "https://bulletproofmusician.com/blog/"
response = URI.open(url)
parsed_page = Nokogiri::HTML(response)
@driver = Selenium::WebDriver.for :firefox

valid_categories = ["Anxiety", "Confidence", "Conversations", "Courage", "Focus", "Practice", "Resilience", "Tools"]

category_urls = {
  #"Conversations" => "https://bulletproofmusician.com/category/conversations/",
  "Anxiety" => "https://bulletproofmusician.com/category/anxiety/",
  "Confidence" => "https://bulletproofmusician.com/category/confidence/",
  "Courage" => "https://bulletproofmusician.com/category/courage/",
  "Focus" => "https://bulletproofmusician.com/category/focus/",
  "Practice" => "https://bulletproofmusician.com/category/practice/",
  "Resilience" => "https://bulletproofmusician.com/category/resilience/",
  "Tools" => "https://bulletproofmusician.com/category/tools/"
}
category_urls = {
  "Anxiety" => "https://bulletproofmusician.com/category/anxiety/",
  "Confidence" => "https://bulletproofmusician.com/category/confidence/",
  "Courage" => "https://bulletproofmusician.com/category/courage/",
  "Focus" => "https://bulletproofmusician.com/category/focus/",
  "Practice" => "https://bulletproofmusician.com/category/practice/",
  "Resilience" => "https://bulletproofmusician.com/category/resilience/",
  "Tools" => "https://bulletproofmusician.com/category/tools/"
}


def extract_image_url(element, *attributes)
  if element.nil?
    puts "Element is nil."
    return nil
  end

  attributes.each do |attribute|
    if element&.attr(attribute)
      #puts "Extracted image URL: #{element.attr(attribute)}"
      return element.attr(attribute)
    end
  end

  puts "No valid attribute found in element: #{element.inspect}"
  return nil
end

def scrape_show_page(agent, post_url)
  page = agent.get(post_url)
  background_element = page.at('.attachment-full.size-full')
  background_url = extract_image_url(background_element, 'data-src', 'src', 'data-srcset')
  #puts "Extracted background URL from show page: #{background_url}" if background_url
  return background_url
end

def scrape_article_content(article_url)
  if article_url.include?("doi.org") or article_url.include?("psycnet.") or article_url.include?('jstor')
    @driver.get(article_url)

    # Scroll down to load lazy content
    @driver.execute_script('window.scrollTo(0, document.body.scrollHeight);')

    sleep(1)  # Adjust sleep duration as needed

    # Parse the lazy-loaded content with Nokogiri
    article_page = Nokogiri::HTML(@driver.page_source)

    article_title = article_page.at('title').text.strip
    puts "what about #{article_title}"
  else
    article_page = Nokogiri::HTML(URI.open(article_url))
    article_title = article_page.at('title').text.strip
    puts "what about #{article_title}"
  end
end

def scrape_category_page(category_name, url)
  agent = Mechanize.new
  page = agent.get(url)

  page.search('.post').each do |post|
    title = post.at('.entry-title').text.strip



    @driver.get(post_url)

    # Scroll down to load lazy content
    @driver.execute_script('window.scrollTo(0, document.body.scrollHeight);')

    sleep(1)  # Adjust sleep duration as needed

    # Parse the lazy-loaded content with Nokogiri
    mypage = Nokogiri::HTML(@driver.page_source)

    mypage.at('.post').search('a').each do |link|
      article_url = link['href']

      #puts "Article URL: #{article_url}"
      next if article_url.include?("bulletproofmusician")
      next if article_url.include?("fusebox")

      scrape_article_content(article_url)
      puts "-------------------"
    end

    puts "-------------------"
  rescue => e
    puts e.message
  end
rescue => e
  puts e.message
end

category_urls.each do |category_name, base_url|
  # Scrape the first page
  scrape_category_page(category_name, base_url)

  # Scrape subsequent pages (assuming 10 pages for demonstration)
  (2..10).each do |page_number|
    paginated_url = "#{base_url}page/#{page_number}/"
    scrape_category_page(category_name, paginated_url)
  rescue => e
    puts e.message
  end
rescue => e
  puts e.message
end

puts "Scraping completed and data stored successfully!"
@driver.quit
