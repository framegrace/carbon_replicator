#!/usr/bin/env ruby
require 'socket'
class Mirror 

  def initialize(hosts)
    @connections=Array.new
    hosts.each do |host|
       hostparams=host.split(':')
       connection={ :host => hostparams[0], :port => hostparams[1] }
       connect(connection)
       @connections<<connection
    end
  end
 
  def connect(connection) 
    begin
      @@log.info "Connecting to  "+connection[:host]+" "+connection[:port].to_s
      connection.store(:socket,TCPSocket.open(connection[:host],connection[:port]))
    rescue
      @@log.error ("Coudn't connect to "+connection[:host]+":"+connection[:port].to_s)
      return false
    end
    @@log.info "Connected"
    return true
  end

  def send_data( data )
    @connections.each do |connection|
       begin
         connection[:socket].puts(data)
       rescue 
         @@log.error "Socket closed to "+connection[:host]+" "+connection[:port].to_s
         if connect(connection)
            connection[:socket].puts(data)
            @@log.info "Reconnected to  "+connection[:host]+" "+connection[:port].to_s
         end
       end
    end
  end
end
