#!/usr/bin/env ruby
require 'socket'
class Mirror 

  def initialize(hosts)
    @hosts=hosts
    @connections=Array.new
    @hosts.each do |host|
       hostparams=host.split(':')
       connection={ :host => hostparams[0], :port => hostparams[1] }
       @connections << connection
    end
  end
 
  def connect_all() 
    @connections.each do |connection|
      connect(connection)
    end
  end
  
  def connect(connection) 
    puts('Connecting to '+connection[:host]+":"+connection[:port].to_s)
    begin
      connection.store(:socket,TCPSocket.open(connection[:host],connection[:port]))
    rescue
      puts ("Coudn't connect to "+connection[:host])
    end
  end

  def send_data( data )
    @connections.each do |connection|
        begin
           connection[:socket].puts(data)
        rescue 
           puts("Socket closed to "+connection[:host]+" "+connection[:port].to_s)
        end
    end
  end
end
