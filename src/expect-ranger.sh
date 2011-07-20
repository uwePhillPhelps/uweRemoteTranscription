#!/usr/bin/expect -f

# Expect script for remote ssh tunnel
# userex = Username for remote access server,
# accessex = Password for remote access server,
# serverex = IP Address of internal server, not hostname
set userex [lrange $argv 0 0]
set accessex [lrange $argv 1 1]
set serverex [lrange $argv 2 2]
set screenLocalportex [lrange $argv 3 3]
set screenRemoteportex [lrange $argv 4 4]
set audioLocalportex [lrange $argv 5 5]
set audioRemoteportex [lrange $argv 6 6]
set fileshareLocalportex [lrange $argv 7 7]
set fileshareRemoteportex [lrange $argv 8 8]
set webLocalportex [lrange $argv 9 9]
set webRemoteportex [lrange $argv 10 10]

set timeout -1
# connect to server
spawn ssh 127.0.0.1 -l $userex -p 5022 \
-L $screenLocalportex/$serverex/$screenRemoteportex \
-L $audioLocalportex/$serverex/$audioRemoteportex \
-L $fileshareLocalportex/$serverex/$fileshareRemoteportex \
-L $webLocalportex/$serverex/$webRemoteportex

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

