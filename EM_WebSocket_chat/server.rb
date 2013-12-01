class ChatServer
  attr_accessor :clients, :rooms
  def initialize
    @clients = []
    @rooms = {"main" => []}
  end

  def forward(msg, sender)
    clients_in_room(sender).each {|c| c.receive_msg("#{sender.username}: #{msg}")}
  end

  def forward_admin(msg, sender)
    clients_in_room(sender).each {|c| c.receive_msg(msg)}
  end

  def clients_in_room(sender)
    @rooms[sender.current_room]
  end
end