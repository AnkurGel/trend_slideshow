require 'open-uri'
class StaticPagesController < ApplicationController
  before_action :initialize_twitter_client

  def home
  end

  def slideshow
    @hashtag = params['twitter']['hashtag']
    count = params['twitter']['count']
    count = count.empty? ? 100 : count.to_i

    if @hashtag.empty?
      redirect_to root_path, notice: "Please enter some hashtag to generate result"
    else
      search_result = @client.search(@hashtag.strip)
      @tweets = search_result.first(count)
      images_urls = find_images_urls(@tweets)

      #Now, we will have to visit those pages,
      #parse them and extract the image
      images = generate_and_save_images(images_urls)

    end
  end

  private

  def initialize_twitter_client
    @client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = "alkome38vee4kkiP1LTA"
      config.consumer_secret     = "CXpdor5DBfhpSOHQns3lnLHImA69sGbVmVYcBBCCLQ"
      config.access_token        = "38638822-y9xgaaZ3KVUiDFdt4JOLWOBzW9wouzBeZNsWs1J31"
      config.access_token_secret = "nhblW71tztuXMOKDv8JWofFDYW9y0uGco75PlSAbNPY0I"
    end
  end

  def find_images_urls(tweets)
    tweets_with_images = tweets.map(&:text).select do |tweet|
      tweet.match(/t\.co/)
    end

    twitter_image_urls = tweets_with_images.map do |tweet|
      URI.extract(tweet).find { |x| x.match(/t.co/) }
    end
    twitter_image_urls
  end

  def generate_and_save_images(image_urls)
    image_urls.each do |url|
      debugger
      url = URI.parse(url)

      # url.scheme = "http" if url.scheme == "https"
      # url.scheme = "https" if url.scheme == "http"

      url = url.to_s
      doc = Nokogiri::HTML(open(url))
      image_permalink = doc.css("#doc #page-outer #page-container div a img")[1].attributes['src'].value

      if image_permalink
        #Save the image in
        #Rails.root/public/images/#{@hashtag}/#{filename}.jpg
        dir = File.join(Rails.too,
                        'public', 'images',
                        "#{@hashtag}")
        Dir.mkdir(dir) unless Dir.exists? dir
        File.open(File.join(dir, image_permalink), 'wb') do |f|
          f.write(File.read(open(image_permalink), 'rb'))
        end
      end
    end
  end
end
