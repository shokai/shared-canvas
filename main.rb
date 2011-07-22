# -*- coding: utf-8 -*-
get '/' do
  @title = @@conf['title']
  haml :index
end

get '/http*' do
  @title = @@conf['title']
  puts @img_url = 'http' + params[:splat].to_s
  haml :draw
end

