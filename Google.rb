require 'nokogiri'
require 'open-uri'
require 'mechanize'
require 'active_record'
require 'selenium-webdriver'
require 'net/http'
require 'uri'
require 'yaml'
@automation_config = {
  metadata: {
    name: 'bulletblog',
    description: 'Scripted automation'
  },
  automations: {
    starters: [
      {
        type: 'assistant.event.OkGoogle',
        eventData: 'query',
        is: 'my bulletproof musician'
      }
    ],
    actions: [
      {
        type: 'assistant.command.Broadcast',
        message: "Article Title: #{article_title}",
        devices: 'Bureau - Bureau'
      },
      {
        type: 'assistant.command.OkGoogle',
        okGoogle: "What's your hobby?"
      },
      {
        type: 'assistant.command.OkGoogle',
        okGoogle: "What's your hobby?"
      },
      {
        type: 'time.delay',
        for: '3sec'
      }
    ]
  }
}

url = "https://bulletproofmusician.com/blog/"
response = URI.open(url)
parsed_page = Nokogiri::HTML(response)
@driver = Selenium::WebDriver.for :firefox

valid_categories = ["Anxiety", "Confidence", "Conversations", "Courage", "Focus", "Practice", "Resilience", "Tools"]

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
  return background_url
end

def scrape_article_content(article_url)
  if article_url.include?("doi.org") or article_url.include?("psycnet.") or article_url.include?('jstor')
    @driver.get(article_url)
    @driver.execute_script('window.scrollTo(0, document.body.scrollHeight);')
    sleep(1)
    article_page = Nokogiri::HTML(@driver.page_source)
  else
    article_page = Nokogiri::HTML(URI.open(article_url))
  end

  article_title = article_page.at('title').text.strip



  @automation_config["automations"]["actions"].push(article_title)
  File.open("bulletblog_automation.yaml", "w") do |file|
    file.write(@automation_config.to_yaml)
  end

  puts "Automation YAML created with article title: #{article_title}"
end

def scrape_category_page(category_name, url)
  agent = Mechanize.new
  page = agent.get(url)

  page.search('.post').each do |post|
    title = post.at('.entry-title').text.strip
    post_url = post.at('.entry-title a')&.attr('href')
    @driver.get(post_url)
    @driver.execute_script('window.scrollTo(0, document.body.scrollHeight);')
    sleep(1)
    mypage = Nokogiri::HTML(@driver.page_source)
    mypage.at('.post').search('a').each do |link|
      article_url = link['href']
      next if article_url.include?("bulletproofmusician")
      next if article_url.include?("fusebox")
      scrape_article_content(article_url)
    end
  rescue => e
    puts e.message
  end
rescue => e
  puts e.message
end

category_urls.each do |category_name, base_url|
  scrape_category_page(category_name, base_url)
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
