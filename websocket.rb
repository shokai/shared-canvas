require 'rubygems'
require 'em-websocket'
require 'json'

port = 8081
port = ARGV.first.to_i if ARGV.size > 0

MAX_LOG = 1000

EM::run do

  puts "server start - port:#{port}"
  @channel = EM::Channel.new
  @logs = Array.new
  @sids = Hash.new
  @channel.subscribe{|mes|
    @logs.push mes
    @logs.shift if @logs.size > MAX_LOG
  }

  EM::WebSocket.start(:host => "0.0.0.0", :port => port) do |ws|
    ws.onopen{
      sid = @channel.subscribe{|mes|
        begin
          data = JSON.parse(mes)
          ws.send(data.to_json) if @sids[sid] == data['img_url']
        rescue => e
          STDERR.puts e
        end
      }
      puts "<#{sid}> connected!!"
      ws.send({:type => :init, :sid => sid}.to_json)

      ws.onmessage{|mes|
        puts "<#{sid}> #{mes}"
        begin
          data = JSON.parse(mes)
          if data['type'].to_s == 'init'
            @sids[sid] = data['img_url']
            @logs.each{|mes|
              begin
                tmp = JSON.parse(mes)
                ws.send(tmp.to_json) if tmp['img_url'] == @sids[sid]
              rescue => e
                STDERR.puts e
              end
            }
          else
            data[:sid] = sid
            @channel.push(data.to_json)
          end
        rescue => e
          STDERR.puts e
        end
      }

      ws.onclose{
        puts "<#{sid}> disconnected"
        @sids.delete(sid)
        @channel.unsubscribe(sid)
        @channel.push({:type => :event, :msg => "#{sid} disconnected"}.to_json)
      }
    }
  end
end
