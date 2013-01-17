#!/usr/bin/env ruby
require 'optparse'
require './relay_server.rb'
require 'logger'

options = {}
options[:queue] = 5000
options[:port] = 2000
options[:flush_delay] = 10
options[:realtime] = false
options[:backend] = 'Mirror'
options[:backend_params] = ''
options[:logfile] = './log/graphite_replicator.log'
options[:pidfile] = './run/graphite_replicator.pid'
options[:shutdown] = false

optparse = OptionParser.new do|opts|
  opts.on('-h','--help','Show usage') do
    puts opts
    exit
  end
  opts.on('-p','--port port','Bind port') do |port|
    options[:port] = port
  end
  opts.on('-l','--logfile logfile','Logfile') do |logfile|
    options[:logfile] = logfile
  end
  opts.on('-i','--pidfile pidfile','Pidfile') do |pidfile|
    options[:pidfile] = pidfile
  end
  opts.on('-q','--queue size','Maximum input queue size') do |size|
    options[:queue] = size
  end
  opts.on('-f','--flush seconds','Flush delay for delayed flushing') do |delay|
    options[:flush_delay] = delay
  end
  opts.on('-r','--realtime','Do not use delayed flushing') do 
    options[:realtime] = true
  end
  opts.on('-s','--shutdown','Shutdown server') do 
    options[:shutdown] = true
  end
  opts.on('-b','--backend Backend type','Type of backend (currently only "Mirror")') do |backend|
    options[:backend] = backend
  end
  opts.on('-P','--backend-params Parameters','Parameters for the backend. For Mirror, host:port,<host:port>,...') do |params|
    options[:backend_params] = params
  end
end
optparse.parse!

@@log = Logger.new(options[:logfile])
if options[:backend_params].empty?
  if !options[:shutdown]
    puts optparse
    exit
  end
end

@@log.level = Logger::INFO

if (options[:shutdown]==true)
  pidfile=File.new(options[:pidfile],'r')
  Process.kill(:SIGINT,pidfile.gets().to_i)
  exit
end

@@log.info("Starting up")
@@log.info("Params: "+options.to_s)
curr_dir=Dir.pwd

Process.daemon

Dir.chdir(curr_dir) do
  begin
    pidfile=File.new(options[:pidfile],'w')
    pidfile.puts(Process.pid.to_s)
    pidfile.flush
    pidfile.close
  rescue
    @@log.error $!
    exit
  end
end

rserver=RelayServer.new( options[:queue], options[:port] ,options[:flush_delay] ,options[:realtime] ,options[:backend], options[:backend_params] )
rserver.start()
trap("SIGINT") {
  rserver.flushQueue()
  exit
}
rserver.server.join
