#!/usr/bin/env ruby
require 'socket'                # Get sockets from stdlib
require 'thread'                # Get sockets from stdlib
require 'timeout'
require './mirror.rb'

class RelayServer

  attr_accessor :server #,:consumer #,:sender_plugin

  # Continously send whatever is in the 
  # queue.
  def realtime_sender() 
    loop {
      @sender_plugin.send_data(@data.pop)
    }
  end
  
  # Scheduler to send the data to graphite
  # no real scheduler on ruby, and the ones
  # I've found are only syntax sugar so we 
  # go for a simple hand made scheduler and
  # avoid more gems to be installed.
  def scheduled_sender( batch_time ) 
    loop {
        sleep(batch_time)
        # Serves to the sender module
        # in a thread to be as scheduler
        # time exact as possible.
        # We may overlap sendings but this can 
        # be good. More threads on more work
        Thread.new do flushQueue() end
      }
  end
  
  # Flush queue until empty
  def flushQueue() 
      puts "Flush"
      while (!@data.empty?) do
          @sender_plugin.send_data(@data.pop)
      end
      puts "Finished"
  end
  
  # Object initialization and thread creation
  def initialize( max_queue_size, server_port, batch_time, realtime, backend, backend_params )

    mirror_hostlist=backend_params.split(',')
    cls = Object.const_get(backend)
    @sender_plugin = cls.new(mirror_hostlist);

    # Queue to store the data
    @data = SizedQueue.new(max_queue_size)
    @server_port = server_port
    @batch_time = batch_time
    @realtime = realtime
  end

  def start() 
    # Server thread. Blocking, but multihreaded
    # explore the non-blocking if needed, but task
    # is so fast that I doubt we will need it.
    @server = Thread.new do
        tserver=TCPServer.open(@server_port)
        puts "Starting Server loop"
        loop {                         
            Thread.start(tserver.accept) do |client|
                begin
	            while line=client.gets() do
                        @data << line 
                    end
                ensure
	          puts "End client"
                  client.close
                end
            end
        }
    end
    # Consumer thread
    @consumer = Thread.new do
      if (@realtime)
        puts "Starting realtime scheduler"
        realtime_sender
      else
        puts "Starting delayed scheduler"
        scheduled_sender(@batch_time)
      end
    end
  end

end

# Control server run with the server
# Any will do
rserver=RelayServer.new( 1000, 2000 ,10 ,false,'Mirror','localhost:2010,localhost:2011' )
rserver.start()
trap("SIGINT") { 
  rserver.flushQueue()
  exit
}
rserver.server.join
