Chitchat
=========

Chitchat is a chat app written with Sinatra, EventMachine, and EM-Websocket. Current features include: creating and joining new rooms, listing available rooms and logged in users, sending private messages, etc.

I built Chitchat to learn about socket programming and concurrency. This mission has led the project through several phases:

1. A simple [chat server using threads](https://github.com/akmcc/Evented/blob/master/threaded_chat_server.rb).
2. [Writing an event loop](https://github.com/akmcc/Evented/blob/master/unthreaded_chat_server.rb) to handle chat messsages.
3. Writing a [chat server using EventMachine](../master/EM_chat.rb).
4. And finally Chitchat: turning phase 3 into a web app by using EM-Websockets with Sinatra.

##How to use it

Download the EM_WebSocket_chat directory. From inside the direcotry, run ```ruby chitchat.rb``` on the command line and navigate to localhost:3000 in as many windows as you like.  Enter <<< help from your browser at any time.

To use the command-line app (#3 above), use netcat. Run ```ruby EM_chat.rb``` from the command line, and type ```nc '0.0.0.0' 9000``` in another terminal window. Open as many windows as you like to simulate a chat.

##To do:

1. Develop the client-side code with separate fields for administrative tasks and chatting.
2. CSS/Bootstrap.
3. Deploy.

##License

WTFPB