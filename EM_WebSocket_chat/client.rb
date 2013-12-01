class ChatClient
  attr_accessor :username, :conn, :id, :current_room
  def initialize(ws, server)
    @username = ""
    @conn = ws
    @server = server
    @current_room = "main"
    @server.rooms["main"] << self
    ws.onmessage do |msg|
      handle_message(msg)
    end
    ws.onclose do
      @server.clients.delete(self)
      @server.rooms[@current_room].delete(self)
    end
  end

  def named?
    @username.empty? ? false : true
  end

  def receive_msg(msg)
    @conn.send(msg)
  end

  def handle_message(msg)
    if named?
      process_message(msg)
    else
      @username = msg.strip
      @server.forward_admin(">>> #{@username} has enterred the room.", self)
    end
  end

  #determine if incoming message is a command, pm, or chat message
  def process_message(msg)
    if msg =~ /^<<</
      handle_commands(msg)
    elsif msg =~ /^@\S+/
      handle_pm(msg)
    elsif msg =~ /^\\/
      @server.forward(msg, self)
    else
      handle_chat_msg(msg)
    end
  end

  #this method and command_checker ensure administrative commmands are not
  #accidentally sent as chat messages
  def handle_chat_msg(msg)
    if command_checker(msg)
      @conn.send(">>> If you meant to send a command, try preceding it with <<<.")
      @conn.send(">>> If not, sorry for butting in. Type a backslash before your chat message whenever your chat message is identical to a command.")
    else
      @server.forward(msg, self)
    end
  end

  def command_checker(msg)
    commands = [/^exit$/, /^rollcall$/, /^create room$/, /^\[/, /^join/, /^list rooms$/, /^size$/, /^help$/]
    commands.each do |c|
      if msg =~ c
        return true
      else
        return false
      end
    end
  end

  def handle_pm(msg)
    match = msg.match(/^@(\S+)\s+(.+)/)
    peer = @server.clients.find { |c| c.username.downcase == match[1].downcase }
    peer.conn.send("PM from @#{@username}: #{match[2]}")
    @conn.send("PM sent to @#{peer.username}: #{match[2]}")
  end 

  def handle_commands(message)
    msg = message.gsub(" ", "")
    if msg =~ /^<<<exit$/i
      @conn.close
    elsif msg =~ /^<<<rollcall$/i
      list_all_users
    elsif msg =~ /^<<<roomcall$/i
      list_users_in_room
    elsif msg =~ /^<<<createroom$/i
      get_room_name
    elsif msg =~ /^<<<\[(.+)\]/
      create_room(message)
    elsif msg =~ /^<<<join/i
      join_room(message)
    elsif msg =~ /^<<<listrooms$/i
      list_rooms
    elsif msg =~ /^<<<size$/i
      room_size
    elsif msg =~ /^<<<help$/i
      help
    elsif msg =~/^<<</
      @conn.send(">>> What's that? I didn't recognize the #{message} command.")
    end
  end

  def list_all_users
    @server.clients.each_with_index {|c, i| @conn.send(">>> #{i+1} #{c.username}")}
  end

  def users_in_room
    @server.rooms[@current_room]
  end

  def list_users_in_room
    users_in_room.each_with_index {|c, i| @conn.send(">>> #{i+1} #{c.username}")}
  end

  def get_room_name
    @conn.send(">>> Enter new room name in brackets (i.e. <<< [motorcycles are cool]:")
  end

  def create_room(msg)
    match = msg.match(/^<<<\s*\[(.+)\]/)
    name = match[1]
    @server.rooms[name] = []
    @conn.send(">>> You've just created the room: #{name}. To join, type \"<<< join #{name}\".")
  end

  def join_room(msg)
    match = msg.match(/^<<<\s*join(.+)/)
    room = match[1].strip
    if room == @current_room
      @conn.send(">>> You're already there, man.")
    else
      @server.forward_admin(">>> #{@username} left for the #{room} room", self)
      users_in_room.delete(self)
      @server.rooms[room] << self
      @current_room = room
      @server.forward_admin(">>> #{@username} joined the #{room} room", self)
    end
  end

  def list_rooms
    @server.rooms.keys.each {|r| @conn.send(">>> #{r}")}
  end

  def room_size
    r = @server.rooms[@current_room].size
    @conn.send(">>> Room size: #{r}")
  end

  def help
    @conn.send(">>> Available commands: exit, rollcall, roomcall, create room, join [room], list rooms, size, @[name] [private message], help")
    @conn.send(">>> Omit [] when supplying input.")
    @conn.send(">>> Precede commands with <<< to distinguish them from chat messages.")
  end  
end
