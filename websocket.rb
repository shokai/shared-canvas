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
  @channel.subscribe{|mes|
    @logs.push mes
    @logs.shift if @logs.size > MAX_LOG
  }

  EM::WebSocket.start(:host => "0.0.0.0", :port => port) do |ws|
    ws.onopen{
      sid = @channel.subscribe{|mes|
        ws.send(mes)
      }
      puts "<#{sid}> connected!!"
      ws.send({:type => :init, :sid => sid}.to_json)
      @logs.each{|mes|
        ws.send(mes)
      }

      ws.onmessage{|mes|
        puts "<#{sid}> #{mes}"
        begin
          data = JSON.parse(mes)
          data[:sid] = sid
          @channel.push(data.to_json)
        rescue => e
          STDERR.puts e
        end
      }

      ws.onclose{
        puts "<#{sid}> disconnected"
        @channel.unsubscribe(sid)
        @channel.push({:type => :event, :msg => "#{sid} disconnected"}.to_json)
      }
    }
  end

  EM::defer do
    loop do
      puts Time.now.to_s
      @channel.push Time.now.to_s
      sleep 60*60*3
    end
  end
end
