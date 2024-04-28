require 'nokogiri'
require 'httparty'
require 'parallel'

Product = Struct.new(:url, :image, :name, :price)

class ParserService
  USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.6.0 Safari/537.36" 
  CSV_HEADERS = ['url', 'image', 'name', 'price']
  PAGE = 'https://scrapeme.live/shop/page/'

  def initialize(pages)
    @products = []
    @pages_to_scrape = pages || generate_pages_to_scrape
  end

  def call
    Parallel.map(@pages_to_scrape, in_threads: 4) do |page|
      begin
        doc = parse_document(page)
        process_document(doc)
      rescue => e
        puts "Something failed while scraping #{page}: #{e.message}"
      end
    end
    save_to_csv
  end

  private

  def generate_pages_to_scrape
    (2..48).map { |p| "#{PAGE}#{p}/" }
  end

  def parse_document(page)
    begin
      response = HTTParty.get(page, headers: { 'User-Agent': USER_AGENT })
      Nokogiri::HTML(response.body)
    rescue => e
      puts "Something failed while getting document #{page}: #{e.message}"
    end
  end

  def process_document(document)
    begin
      document.css('li.product').each do |html_product|
        url = html_product.css('a')[0].attribute('href').value 
        image = html_product.css('img')[0].attribute('src').value 
        name = html_product.css('h2')[0].text 
        price = html_product.css('span')[0].text 

        product = Product.new(url, image, name, price) 

        Mutex.new.synchronize {
          @products.push(product)
        }
      end
    rescue => e
      puts "Something failed while processing document: #{e.message}"
    end
  end

  def save_to_csv
    begin
      CSV.open('output.csv', 'wb', write_headers: true, headers: CSV_HEADERS) do |csv| 
        @products.each do |product| 
          csv << product 
        end 
      end
    rescue => e
      puts "Something failed while writing to CSV: #{e.message}"
    end
  end
end

begin
  parser = ParserService.new
  parser.call
rescue => e
  puts "Something failed while creating parser object or starting parsing: #{e.message}"
end
