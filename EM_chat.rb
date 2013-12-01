#basic EM chat server
#current commands: exit, create room, join room, list rooms, rollcall, @user pm
#command-line application

require 'eventmachine'

class ChatServer
  attr_accessor :clients, :rooms

  def initialize(host, port)
    @host = host
    @port = port
    @clients = []
    @rooms = {"main" => []}
  end

  def start!
    EM.start_server(@host, @port, ChatClient) do |client|
      @clients << client
      client.server = self
    end
  end
end

class ChatClient < EM::Connection
  attr_accessor :username, :server

  #EM::Connection built-ins
  def post_init
    @username = nil
    get_username
  end

  def unbind
    @server.clients.delete(self)
    users_in_room.delete(self)
    puts "#{username} left the chat" if entered_username?
    other_peers.each {|c| c.send_line("#{username} left the chat")}
  end

  def receive_data(data)
    if entered_username?
      handle_chat_message(data.strip)
    else
      handle_username(data.strip)
    end
  end

  #Username methods
  def get_username
    send_line("Enter username:")
  end

  def send_line(line)
    send_data("#{line}\r\n")
  end

  def entered_username?
    !@username.nil? && !@username.empty?
  end

  def handle_username(input)
    if input.empty?
      send_line("No blank usernames. Try again.")
      get_username
    else
      @username = input
      @server.clients << self
      @server.rooms["main"] << self
      other_peers.each {|c| c.send_line("#{@username} has joined the chat!")}
      puts "#{@username} has joined"
      send_line("Hi there, #{@username}.")
    end
  end

  #Message methods
  def handle_chat_message(msg)
    if msg =~ /^exit$/i
      self.close_connection
    elsif msg =~ /^rollcall$/i
      self.list_all_users
    elsif msg =~ /^create room$/i
      get_room_name
    elsif msg =~ /^\[/
      create_room(msg)
    elsif msg =~ /^join/i
      join_room(msg)
    elsif msg =~ /^list rooms$/i
      list_rooms
    elsif msg =~ /^size/
      room_size
    elsif msg =~ /^@\S+/
      handle_pm(msg)
    else
      other_peers.each { |c| c.send_line("#{self.username}: #{msg}") }
    end
  end

  def handle_pm(msg)
    match = msg.match(/^@(\S+)\s+(.+)/)
    peer = @sever.clients.find { |c| c.username.downcase == match[1].downcase }
    peer.send_data("PM from #{@username}: #{match[2]}")
  end

  #Room methods
  def get_room_name
    send_line("Enter new room name in brackets (i.e. [motorcycles are cool]:")
  end

  def create_room(msg)
    match = msg.match(/^\[(.+)\]/)
    name = match[1]
    @server.rooms[name] = []
    send_line("You've just created the room: #{name}. To join, type \"join #{name}\".")
  end

  def current_room
    @server.rooms.each {|k,v| return k if v.include?(self)}    
  end

  def users_in_room
    @server.rooms[current_room]
  end

  def list_rooms
    @server.rooms.keys.each_with_index {|room, i| send_line("#{i+1} #{room}")}
  end

  def join_room(msg)
    match = msg.match(/^join (.+)/)
    room = match[1]
    other_peers.each {|c| c.send_line("#{username} left for the #{room} room")}
    users_in_room.delete(self)
    @server.rooms[room] << self
  end

  def room_size
    send_line(users_in_room.size)
  end

  #other user methods
  def other_peers  
    users_in_room.reject { |c| c == self}
  end

  def list_all_users
    send_line("In this room:")
    if self.other_peers.size == 0
      send_line("Just you, all by your lonesome.")
    else
      self.other_peers.each_with_index {|client, i| send_line("#{i+1} #{client.username}")}
    end
  end

end

EM.run do
  server = ChatServer.new('0.0.0.0', 9000)
  server.start!
end