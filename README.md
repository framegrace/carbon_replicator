carbon_replicator
=================

Replicates graphite carbon (or any other "line" based protocol) requests to multiple backends

<pre>
Usage: carbon_replicator [options]
    -h, --help                       Show usage 
    -p, --port port                  Bind port (2000)
    -l, --logfile logfile            Logfile (./log/carbon_replicator.log)
    -i, --pidfile pidfile            Pidfile (./run/carbon_replicator.log)
    -q, --queue size                 Maximum input queue size (5000)
    -f, --flush seconds              Flush delay for delayed flushing (10)
    -d, --daemonize                  Daemonize server
    -r, --realtime                   Do not use delayed flushing (false)
    -s, --shutdown                   Shutdown server (false)
    -b, --backend Backend type       Type of backend (currently only "Mirror")  (Mirror)
    -P, --backend-params Parameters  Parameters for the backend. For Mirror, host:port,[host:port],... (mandatory)
</pre>
Examples:

Listens on port 2000 and replicates to localhost:2019 and localhost:2020 every 10s.
<pre>
./carbon_replicator.rb -P localhost:2019,localhost:2020
</pre>
 Listens on port 2000 and replicates to localhost:2019 and localhost:2020 every request.
<pre>
./carbon_replicator.rb -r  -P localhost:2019,localhost:2020
</pre>
