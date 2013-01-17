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
    done=0
    while (!@data.empty?) do
      done=done+1
      @sender_plugin.send_data(@data.pop)
    end
    @@log.info "Flushed "+done.to_s
  end
  
  # Object initialization and thread creation
  def initialize( max_queue_size, server_port, batch_time, realtime, backend, backend_params )
    mirror_hostlist=backend_params.split(',')
    @@log.info "Initializing "+backend+" backend." 
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
      @@log.info "Starting Server loop"
      loop {                         
        Thread.start(tserver.accept) do |client|
          begin
            @@log.debug "New client"
            while line=client.gets() do
              @data << line 
            end
          ensure
            @@log.debug "End client"
            client.close
          end
        end
      }
    end
    # Consumer thread
    @consumer = Thread.new do
      if (@realtime)
        @@log.info "Starting realtime scheduler"
        realtime_sender
      else
        @@log.info "Starting delayed scheduler"
        begin
          scheduled_sender(@batch_time)
        rescue
          @@log.error $!
        end
      end
    end
  end

end
