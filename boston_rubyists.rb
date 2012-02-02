require 'sinatra'
require 'sequel'
require 'json'
require 'logger'
require 'nokogiri'
DB = Sequel.connect "postgres:///bostonruby", logger: Logger.new(STDERR)

class BostonRubyists < Sinatra::Base

  helpers {
    def prep(p)
      p[:date_string] = p[:date].strftime("%b %d %I:%M %p")
      if p[:content] 
        p[:content] = p[:content].sub(/\w+ \d+, \d{4}/, '')
      end
      if p[:summary] && (n = Nokogiri::HTML(p[:summary]).at('p'))
         words = n.inner_text[0,355].split(/\s/)
         p[:summary] = words[0..-2].join(' ') + '...' 
        
      end
      p
    end
  }

  get('/') {
    @updates = DB[:updates].order(:date.desc).limit(110).map {|u| prep u}
    @blog_posts = DB[:blog_posts].order(:date.desc).limit(90).map {|p| prep p}
    erb :index 
  }

  get('/updates') {
    ds = DB[:updates].order(:date.desc).filter("date > ?", params[:from_time])
    puts "returning #{ds.count} results"
    @updates = ds.map {|u| prep u}
    @updates.to_json
  }
  get('/blog_posts') {
    ds = DB[:blog_posts].order(:date.desc).filter("date > ?", params[:from_time])
    puts "returning #{ds.count} results"
    @blog_posts = ds.map {|p| prep p}
    @blog_posts.to_json
  }

  run! if app_file == $0
end
