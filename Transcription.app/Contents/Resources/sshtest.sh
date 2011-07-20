#!/usr/bin/expect -f
#sshtest.sh

set filename /tmp/sshtest.txt
set server 164.11.131.66

set timeout 5
# connect to server
set fp [open $filename w]

puts $fp initialise

spawn /usr/bin/ssh -l test $server
match_max 100000

expect 	{
		
		"*No route to host*" {puts $fp fail}
		"*Network is down*" {puts $fp fail}		
		"*(yes/no)?*" {puts $fp succeed}
		"*?assword:*" {puts $fp succeed}
		
		}

close $fp
exit 0

# 201 -> Success 			- Can see RAS ssh available
# 202 -> Failure 			- Can't See Server


