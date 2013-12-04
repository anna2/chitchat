#connect using "nc '0.0.0.0' 9393"

require 'socket'

server = TCPServer.new('0.0.0.0',9393)
@users = []

#monitor the server for new connections in a background thread
Thread.new do
  Socket.accept_loop(server) do |client|
    @users << client
    client.write("Welcome to the chatroom!")
  end
end

#monitor exisiting clients for new messages in the main thread
loop do 
  if @users.size > 0
    readables, _ = IO.select(@users)
    readables.each do |readable|
      msg = readable.read_nonblock(1024)    
      @users.each do |user|
        user.write_nonblock(msg)
      end
    end
  end
end
