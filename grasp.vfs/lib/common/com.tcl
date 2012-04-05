#
# send a message to a host over TCP
#

proc send {message host port} {
  set channel [socket $host $port]
  puts $channel $message
  close $channel
  debug "sent $message to $host:$port"
}

#
# Send a string over a socket channel (without a new line at the end)
#

proc sends {channel message} {
  puts -nonewline $channel $message
  flush $channel
  debug  "sent '$message' to [peername $channel]"
}

#
# Return 'host:port' of the remote end point of a socket channel.
#

proc peername {channel} {
  set peername [fconfigure $channel -peer]
  
  # distinguish between udp and tcp sockets
  if {[llength $peername] == 2} {
    return "[lindex $peername 0]:[lindex $peername 1]"
  } else {
    return "[lindex $peername 1]:[lindex $peername 2]"
  }
}




