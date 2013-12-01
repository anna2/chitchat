require 'em-websocket'
require 'sinatra/base'
require 'erb'
require 'thin'

require_relative 'client'
require_relative 'server'

EventMachine.run do
  class ChitChat < Sinatra::Base
    get '/' do
      erb :index
    end
  end
  
  @server = ChatServer.new

  EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8080) do |ws|
    ws.onopen do
      @server.clients << ChatClient.new(ws, @server)
      ws.send(">>> Please enter a username: ")
    end
  end

  ChitChat.run!({:port => 3000})
end