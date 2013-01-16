#!/usr/bin/env ruby
require 'socket'
class Mirror 

  def connector
    wrongs = Array.new()
    loop {
      while(!@disconnected.empty?) do
        connection=@disconnected.pop
        if (connect(connection))
          @connections << connection
        else
          wrongs << connection
        end
      end
      wrongs.each do |connection| 
        @disconnected << connection
      end
      wrongs=Array.new
      sleep(@reconnect_interval)
    }
  end

  def initialize(hosts)
    @hosts=hosts
    @connections=Array.new
    @disconnected = Array.new()
    @reconnect_interval=20
    @hosts.each do |host|
       hostparams=host.split(':')
       connection={ :host => hostparams[0], :port => hostparams[1] }
       @disconnected << connection
    end
    @reconnector= Thread.new do
      connector()
    end
  end
 
  def connect(connection) 
    puts('Connecting to '+connection[:host]+":"+connection[:port].to_s)
    begin
      connection.store(:socket,TCPSocket.open(connection[:host],connection[:port]))
    rescue
      puts ("Coudn't connect to "+connection[:host]+":"+connection[:port].to_s)
      return false
    end
    return true
  end

  def send_data( data )
    @connections.each do |connection|
       begin
         connection[:socket].puts(data)
       rescue 
         puts("Socket closed to "+connection[:host]+" "+connection[:port].to_s)
         @disconnected.add(connection)
       end
    end
  end
end
