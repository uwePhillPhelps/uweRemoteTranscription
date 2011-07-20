#!/bin/sh
server=164.11.131.66
testserver=www.google.co.uk

ping -c 1 -t 3 $server > /dev/null
#if 100% packet loss - failed ping
if [ $? -gt 0 ]
then 
blank=1
#echo no response from $server on `date`
else 
echo 101
exit 0
#echo succeeded to $server on `date` 
fi
#can we connect to some other server?
ping -c 1 -t 3 $testserver > /dev/null
# if we can't ping the outside, then record so
if [ $? -gt 0 ]
then
blank=2 
#echo no response from $testserver on `date` 
else 
echo 102
#echo succeeded to $testserver on `date`
exit 0
fi
blank=3
echo 103
exit 0

# returned (in this case echoed) values
# 101 -> Success 			- Can see RAS
# 102 -> Partial Success 	- Can't See RAS but can see UWE Web server
# 103 -> Failure 			- Can't see anything 
