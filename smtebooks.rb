require 'bundler/setup'
require 'fury'
require 'pry'
require 'json'

class SmteBooks

  NO_OF_THREADS = 2

  def initialize(params)
    @domain = params[:domain]
    @category = params[:category]
    @pages = params[:pages]
  end

  def get_book_list(url)
    Fury.run_now %Q(curl #{url} | grep -E "a href=\\\"/book")
  end

  def get_book_file(url)
  end

  def extract_book_details(book_list_html)
    book_list_html.scan(/href=\"(.*)\"\sname=\"(.*)\"/i)
  end

  def format_extracted_list(extracted)
    list = {}
    extracted.each do |books|
      list.merge!(
        {
          "#{Time.now.strftime('%Y%m%D%H%M%S%L%N')}":{
            title: books[1], url: "#{@domain}/#{books[0]}", download: download_url(books[0])
          }
        }
      )
    end
    list.to_json
  end

  def download_url(book_url)
    book_id = book_url.scan(/book\/(\d*)\//i).flatten
    url = "#{@domain}/file/#{book_id[0]}"
    download_links_html = Fury.run_now(%Q(curl #{url} | grep -E "href=\\\"https://drive"))
    download_links = download_links_html.scan(/href=\"(.*)\"\starget/i).flatten
    download_links[0]
  end

  def pp_json(to_json)
    JSON.pretty_unparse(JSON.parse to_json)
  end

  def collect_book_per_page(page)
    path = %Q(#{Dir.pwd}/book_list/#{@category})
    Fury.run_now(%Q(mkdir -p #{path}))
    file = File.open("#{path}/page_no_#{page}", "w")
    puts '#'*80
    puts "Page no. #{page}"
    puts '#'*80
    book_list_html = get_book_list("#{@domain}/Category/#{@category}?page=#{page}")
    extracted = extract_book_details(book_list_html)
    output_json = format_extracted_list(extracted)
    file.write(pp_json(output_json))
    file.close
  end

  def collect_books
    threads = []
    (@pages[:start]..@pages[:end]).each do |page|
      puts '#'*80
      puts "starting thread for page #{page}"
      puts '#'*80
      threads << Thread.new {
        collect_book_per_page(page)
     }
      sleep(5)
      puts '#'*80
      puts "was sleeping for 5"
      puts '#'*80
      threads.each(&:join) if threads.size%NO_OF_THREADS == 0
      puts '#'*80
      puts "threads completion waiting after page #{page}"
      puts '#'*80
    end
    puts 'Completed mission !!!!!'

  end

end



params = {
  domain: 'https://smtebooks.com',
  category: 'programming-it',
  pages: {start: 1, end: 411}
}

smte_books = SmteBooks.new(params)
smte_books.collect_books
