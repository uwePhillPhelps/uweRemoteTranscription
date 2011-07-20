#!/usr/bin/expect -f

# Expect script for remote ssh tunnel
# This script needs three argument to create the tunnel:
# userex = Username for remote access server,
# accessex = Password for remote access server,
# serverex = IP Address of internal server, not hostname
set userex [lrange $argv 0 0]
set accessex [lrange $argv 1 1]
set serverex [lrange $argv 2 2]

# localportex and remoteportex not used but there for future flexibility
set localportex [lrange $argv 3 3]
set remoteportex [lrange $argv 4 4]

set timeout -1
# connect to server
spawn ssh $userex@164.11.131.66 -L $localportex/$serverex/$remoteportex
match_max 100000

for {set i 0} {$i<2} {incr i 1} {
expect 	{
		"*No route to host*" {exit 101}		
		"*command]*"  {exit 102}
		"*(yes/no)?*" {send -- "yes\r"}
		"*?assword:*" {send -- "$accessex\r"}
		}
}


expect 	{
		"*?assword:*" {exit 103}		
		}

send -- "\r"
expect eof

#interact

# error 101 => No route to host - network error
# error 102 => incorrect ssh syntax
# error 103 => username/password error

