#!/usr/bin/env ruby
require 'socket'
class Mirror 

  def initialize(hosts)
    @hosts=hosts
    @sockets=Array.new
  end
 
  def connect() 
    @hosts.each do |host|
       hostparams=host.split(':')
       puts('Connecting to '+hostparams[0]+":"+hostparams[1])
       @sockets << TCPSocket.open(hostparams[0], hostparams[1])
    end
  end

  def send_data( data )
    @sockets.each do |socket|
        begin
           socket.puts(data)
        rescue 
           puts("Socket closed")
        end
    end
  end
end
