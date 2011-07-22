require 'rubygems'
require 'em-websocket'
require 'json'

port = 8081
port = ARGV.first.to_i if ARGV.size > 0

MAX_LOG = 100000

EM::run do

  puts "server start - port:#{port}"
  @channel = EM::Channel.new
  @logs = Array.new
  @sids = Hash.new
  @channel.subscribe{|data|
    @logs.push data if data['type'].to_s != 'cmd'
    while @logs.size > MAX_LOG
      @logs.shift
    end
  }

  EM::WebSocket.start(:host => "0.0.0.0", :port => port) do |ws|
    ws.onopen{
      sid = @channel.subscribe{|data|
        ws.send(data.to_json) if data['img_url'] == @sids[sid]
      }
      puts "<#{sid}> connected!!"
      ws.send({:type => :init, :sid => sid}.to_json)

      ws.onmessage{|mes|
        puts "<#{sid}> #{mes}"
        begin
          data = JSON.parse(mes)
          if data['type'].to_s == 'init'
            @sids[sid] = data['img_url']
            @logs.each{|data|
              ws.send(data.to_json) if data['img_url'] == @sids[sid]
            }
          else
            if data['type'].to_s == 'cmd'
              if data['cmd'].to_s == 'reset'
                img_url = @sids[sid]
                @logs = @logs.delete_if{|log|
                  log['img_url'] == img_url
                }
              end
            end
            data['sid'] = sid
            data['img_url'] = @sids[sid]
            @channel.push(data)
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
