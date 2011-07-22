# -*- coding: utf-8 -*-
get '/' do
  @title = @@conf['title']
  haml :index
end

get '/http*' do
  puts @img_url = 'http' + params[:splat].to_s
  haml :draw
end

