---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--  Created by Gethin John on 29/04/2009.
-- Modified by Phill Phelps October 2010.
--  Copyright 2010 University of the West of England. All rights reserved.
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
global UseServer
global theWindow

on awake from nib theObject
	-- In this Case "theObject" is the window itself
	set theWindow to theObject
	tell theWindow
		set contents of text field "netstatus" of theWindow to "Testing..."
		set contents of text field "status" of theWindow to "Idle"
		set visible of text field "status" to true
		update
	end tell
	---------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------
	try
		do shell script "rm /private/tmp/sshtest.txt"
	end try
	--*******Get Path to network script *********--
	
	tell application "Finder" to get (path to me) as Unicode text
	set workingDir to quoted form of POSIX path of result
	set scriptpath to "" & workingDir & "" & "Contents/Resources"
	set networktest to "fail"
	--------------------------------------------------------------
	do shell script "" & scriptpath & "/sshtest.sh"
	-------------------------------------------------------------
	set pathString to "/private/tmp/sshtest.txt"
	set theFile to POSIX file pathString
	open for access theFile
	set networktest to (read theFile)
	close access theFile
	
	--debug
	--display dialog "" & networktest & ""
	-----------------------------------------------------------------
	
	if networktest contains "succeed" then
		tell theWindow
			set contents of text field "netstatus" of theWindow to "Online"
			update
		end tell
		
	else
		if networktest contains "fail" then
			tell theWindow
				set contents of text field "netstatus" of theWindow to "Remote Server Unavailable"
				update
			end tell
		else
			tell theWindow
				set contents of text field "netstatus" of theWindow to "Remote Server Unavailable"
				update
			end tell
			
		end if
	end if
	
	--kill any existing ssh tunnels to 164.11.131.66
	try
		do shell script "kill -HUP `ps -ax | grep 164.11.131.66 | grep -v grep | awk '{print $1}'`"
	end try
	
end awake from nib
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
on clicked theObject
	if name of theObject is "Connect" then
		
		set theWindow to window of theObject
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		--*******User Interface Stuff*********--
		tell theWindow
			set visible of button "Connect" to false
			set visible of button "Disconnect" to true
			set visible of progress indicator "progress" to true
			set uses threaded animation of progress indicator "progress" to true
			start progress indicator "progress"
			set visible of text field "status" to true
			set contents of text field "status" of theWindow to "Connecting..."
		end tell
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		--*******Collect Connection info from UI*********--
		tell theWindow
			set User to contents of text field "Username"
			set Access to contents of text field "Password"
			set ConnectionIndex to contents of button "Type"
			
			if ConnectionIndex is equal to 0 then set Server to "InternalTranscription"
			if ConnectionIndex is equal to 1 then set Server to "ExternalTranscription"
			
			
		end tell
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		--*******Set IP Addresses*********--
		if Server = "InternalTranscription" then
			
			(*
			--*******Get Path to aulab executable, .trak file, and vnc location *********--
			tell application "Finder" to get (path to me) as Unicode text
			set workingDir to POSIX path of result
			set scriptpath to workingDir & "Contents/Resources/"
			
			set vncloc_alias to quoted form of (scriptpath & "internalDesktop-step1.vncloc") as alias
			tell application "Finder" to open vncloc_alias
			
			
			--set aulabtrak_alias to quoted form of (scriptpath & "internalAudio-step2.trak") as alias
			--tell application "Finder" to open aulabtrak_alias
			*)
			
			tell application "Finder" to get (path to me) as alias
			tell application "Finder" to get result as string -- container of result
			set desktop_alias to result & "Contents:Resources:internalDesktop.vncloc" as alias
			
			
			tell application "Finder" to get file creator of (info for (path to application "Finder"))
			set finder_creator to result as string
			tell application "Finder" to open desktop_alias using application file id finder_creator
			
			
		end if
		
		if Server = "" then
			set rangerip to "164.11.8.49"
			set localrangerport to "5022"
			set remoterangerport to "22"
		end if
		
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		--*******Temporary move of known hosts*********--
		try
			do shell script "mv -f ~/.ssh/known_hosts ~/.ssh/known_hosts_temp"
		end try
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		--*******Get Path to expect script *********--
		tell application "Finder" to get (path to me) as Unicode text
		set workingDir to quoted form of POSIX path of result
		set scriptpath to "" & workingDir & "" & "Contents/Resources"
		
		--******** Use expect Script to establish connection *********--
		do shell script "" & scriptpath & "/expect.sh " & User & " " & Access & " " & ipadd & " " & localport & " " & remoteport & " > /dev/null 2>&1 &"
		
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		
		set sshdone to false
		set sftpdone to false
		set accesstest to false
		set fetchstatus to "Fetch Error"
		
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		
		set counter to 0
		repeat 6 times
			set sshtest to (do shell script "ps -ax | grep 164.11.131.66 | grep -v grep | awk '{print $4}'")
			if sshtest is equal to "ssh" then
				set sshdone to true
				set counter to (counter + 1)
				
				if sshtest is equal to "ssh" and (counter is greater than 2) then
					tell theWindow
						set contents of text field "status" of theWindow to "ssh connection started..."
						update
					end tell
					exit repeat
				else
					delay 1
				end if
			end if
		end repeat
		
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		if Server is not equal to "Cache" then
			repeat 6 times
				if sshdone then
					(*
					tell application "Fetch"
						try
							make new transfer window at beginning with properties {hostname:"127.0.0.1", port:5022, username:"" & User & "", password:"" & Access & "", authentication:SFTP, encrypt:true}
						end try
						
					end tell
				 *)
					exit repeat
					--this needs fixing
				else
					delay 1
				end if
			end repeat
			
			---------------------------------------------------------------------------------------------
			---------------------------------------------------------------------------------------------
			
			repeat 5 times
				(*
				tell application "Fetch"
					try
						set fetchstatus to status of transfer window 1
					end try
			  
				end tell
			  *)
				
				if (fetchstatus is "Connected.") then
					--set sftpdone to true
					set accesstest to true
					exit repeat
				else
					delay 1
					set accesstest to false
				end if
			end repeat
			
		else
			display dialog "" & Server & ""
		end if
		if Server is equal to "Cache" then
			delay 1
			set accesstest to true
		end if
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		if accesstest then
			tell theWindow
				--set contents of text field "status" of theWindow to "sftp connection done "
				stop progress indicator "progress"
				set visible of progress indicator "progress" to false
				set visible of text field "status" to true
				if Server is equal to "Cache" then
					delay 1
					set contents of text field "status" of theWindow to "uWEB connection done "
				else
					set contents of text field "status" of theWindow to "sftp connection done "
				end if
				
			end tell
		else
			tell theWindow
				set contents of text field "status" of theWindow to "Authentication Failed"
				stop progress indicator "progress"
				set visible of progress indicator "progress" to false
				
			end tell
		end if
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
	else
		
		if name of theObject is "Disconnect" then
			set theWindow to window of theObject
			
			try
				do shell script "kill -HUP `ps -ax | grep 164.11.131.66 | grep -v grep | awk '{print $1}'`"
			end try
			try
				do shell script "mv -f ~/.ssh/known_hosts_temp ~/.ssh/known_hosts"
			end try
			
			tell theWindow
				--set visible of progress indicator "progress" to false
				set visible of button "Connect" to true
				set visible of button "Disconnect" to false
				set visible of progress indicator "progress" to false
				set contents of text field "status" of theWindow to "Disconnected"
				stop progress indicator "progress"
			end tell
			delay 1
			tell theWindow
				set contents of text field "status" of theWindow to "Idle"
			end tell
			---------------------------------------------------------------------------------------------
			---------------------------------------------------------------------------------------------
		else
			
			if name of theObject is "Initialise" then
				set theWindow to window of theObject
				tell theWindow
					set contents of text field "Username" to ""
					set contents of text field "Password" to ""
					set contents of text field "netstatus" of theWindow to "Testing..."
					set contents of text field "status" of theWindow to "Idle"
					set visible of button "Connect" to true
					set visible of button "Disconnect" to false
					set visible of progress indicator "progress" to false
					update theWindow
				end tell
				try
					do shell script "rm /private/tmp/sshtest.txt"
				end try
				
				try
					do shell script "kill -HUP `ps -ax | grep 164.11.131.66 | grep -v grep | awk '{print $1}'`"
				end try
				
				tell application "Finder" to get (path to me) as Unicode text
				set workingDir to quoted form of POSIX path of result
				set scriptpath to "" & workingDir & "" & "Contents/Resources"
				set networktest to "fail"
				--------------------------------------------------------------
				do shell script "" & scriptpath & "/sshtest.sh"
				--------------------------------------------------------------
				set pathString to "/private/tmp/sshtest.txt"
				set theFile to POSIX file pathString
				
				open for access theFile
				set networktest to (read theFile)
				close access theFile
				-----------------------------------------------------------------
				
				if networktest contains "succeed" then
					tell theWindow
						set contents of text field "netstatus" of theWindow to "Online"
						update
					end tell
					
				else
					if networktest contains "fail" then
						tell theWindow
							set contents of text field "netstatus" of theWindow to "Remote Server Unavailable"
							update
						end tell
					else
						tell theWindow
							set contents of text field "netstatus" of theWindow to ""
							update
						end tell
						
					end if
				end if
				try
					do shell script "rm /private/tmp/sshtest.txt"
				end try
				
			end if
			---------------------------------------------------------------------------------------------
			---------------------------------------------------------------------------------------------
		end if
	end if
	
end clicked

on choose menu item theObject
	(*Add your script here.*)
end choose menu item

(*
on choose menu item theObject
	set userGuide to (resource path of main bundle) & "/BIT Remote Access Guide.html"
	--display dialog "" & userGuide & ""
	
	tell application "Help Viewer"
		open userGuide
	end tell
end choose menu item
*)



