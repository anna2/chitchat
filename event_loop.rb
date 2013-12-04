#connect using "nc '0.0.0.0' 9393"
require 'socket'

class ChatServer

  def initialize
    @server = TCPServer.new(9393)
    @users = [@server]
    start_server
  end

  def start_server
    loop do
      readables, _ = IO.select(@users)
      readables.each do |socket|
        if socket == @server
          @users << (socket.accept_nonblock)
          @users[-1].write("Welcome to the chatroom.")
        else
          message = socket.read_nonblock(1024)
          if message.strip.match(/exit/)
            socket.close
            @users.delete(socket)
          else
            @users[1..-1].each do |user|
              user.write_nonblock(message)
            end
          end
        end
      end
    end 
  end
end

a = ChatServer.new