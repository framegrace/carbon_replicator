#!/usr/bin/env ruby
require 'optparse'
require './relay_server.rb'

options = {}
options[:queue] = 5000
options[:port] = 2000
options[:flush_delay] = 10
options[:realtime] = false
options[:backend] = 'Mirror'
options[:backend_params] = ''

optparse = OptionParser.new do|opts|
  opts.on('-h','--help','Show usage') do
    puts opts
    exit
  end
  opts.on('-p','--port port','Bind port') do |port|
    options[:port] = port
  end
  opts.on('-q','--queue size','Maximum input queue size') do |size|
    options[:queue] = size
  end
  opts.on('-f','--flush seconds','Flush delay for non realtime mode') do |delay|
    options[:flush_delay] = delay
  end
  opts.on('-r','--realtime','Do not use delayed flushing') do 
    options[:realtime] = true
  end
  opts.on('-b','--backend Backend type','Type of backend (currently only "Mirror")') do |backend|
    options[:backend] = backend
  end
  opts.on('-P','--backend-params Parameters','Parameters for the backend. For Mirror, host:port,<host:port>,...') do |params|
    options[:backend_params] = params
  end
end
optparse.parse!

# use optparse to get hostname from the -H flag...
if options[:backend_params].empty?
  puts optparse
  exit
end
# Control server run with the server
# Any will do
rserver=RelayServer.new( options[:queue], options[:port] ,options[:flush_delay] ,options[:realtime] ,options[:backend], options[:backend_params] )
rserver.start()
trap("SIGINT") {
  rserver.flushQueue()
  exit
}
rserver.server.join
