---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--  Created by Gethin John on 29/04/2009.
-- Modified by Phill Phelps October 2010.
--  Copyright 2010 University of the West of England. All rights reserved.
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
global UseServer
global theWindow

property rangerrIp : "164.11.8.49"
property remoteIp : "164.11.13.196"
property remoteDropboxPath : "/ppad's Public Folder/Drop Box"

-- this is pretty sloppy
property fileSharingLocalPort : ""

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
	try
		do shell script "" & scriptpath & "/sshtest.sh"
	end try
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
				set contents of text field "netstatus" of theWindow to "UWE RAS unavailable"
				update
			end tell
		else
			tell theWindow
				set contents of text field "netstatus" of theWindow to "Network test failed"
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
		
		if Server is "ExternalTranscription" then
			
			--******* Set ranger ports for tunnel thru RAS *********--
			set localrangerport to "5022"
			set remoterangerport to "22"
			
			--******* Set mmini ports for second tunnel thru ranger *********--
			set screenLocalPort to "5906"
			set screenRemotePort to "5900"
			set audioLocalPort to "5280"
			set audioRemotePort to "5280"
			set fileSharingLocalPort to "6548"
			set fileSharingRemotePort to "548"
			set webLocalPort to "8086"
			set webRemotePort to "80"
			
			---------------------------------------------------------------------------------------------
			---------------------------------------------------------------------------------------------
			
			--*******Temporary move of known hosts*********--
			try
				do shell script "mv -f ~/.ssh/known_hosts ~/.ssh/known_hosts_temp"
			end try
			
			---------------------------------------------------------------------------------------------
			---------------------------------------------------------------------------------------------
			
			--******** Progress flags *******--
			set firststage to false
			set secondstage to false
			
			--*******Get Path to expect-ras script *********--
			tell application "Finder" to get (path to me) as Unicode text
			set workingDir to quoted form of POSIX path of result
			set scriptpath to "" & workingDir & "" & "Contents/Resources"
			
			--******** Use expect RAS  *********--
			try
				do shell script "" & scriptpath & "/expect-ras.sh " & User & " " & Access & " " & rangerrIp & " " & localrangerport & " " & remoterangerport & " > /dev/null 2>&1 &"
			end try
			
			delay 1
			
			--******* Test progress with timeout *******--
			repeat 6 times
				set sshtest to ""
				try
					set sshtest to (do shell script "ps -ax | grep 164.11.131.66 | grep -v grep")
				end try
				
				if sshtest contains "ssh" and sshtest contains User then
					set firststage to true
					tell theWindow
						set contents of text field "status" of theWindow to "stage 1 of 2 complete"
						update
					end tell
					delay 1
					exit repeat
				else
					delay 1
				end if
			end repeat
			
			---------------------------------------------------------------------------------------------
			---------------------------------------------------------------------------------------------
			
			if firststage then
				--*******Get Path to expect-ranger script *********--
				tell application "Finder" to get (path to me) as Unicode text
				set workingDir to quoted form of POSIX path of result
				set scriptpath to "" & workingDir & "" & "Contents/Resources"
				
				--******** Use expect Script to establish connection to ranger  *********--
				delay 1
				
				try
					set shellCommand to "" & scriptpath & "/expect-ranger.sh " & User & " " & Access & " "
					set shellCommand to shellCommand & remoteIp & " "
					set shellCommand to shellCommand & screenLocalPort & " " & screenRemotePort & " "
					set shellCommand to shellCommand & audioLocalPort & " " & audioRemotePort & " "
					set shellCommand to shellCommand & fileSharingLocalPort & " " & fileSharingRemotePort
					set shellCommand to shellCommand & " > /dev/null 2>&1 &"
					do shell script shellCommand
				end try
				
				delay 1
				
				--******* Test progress with timeout *******--
				repeat 6 times
					set sshtest to ""
					try
						set sshtest to (do shell script "ps -ax | grep 127.0.0.1 | grep -v grep")
					end try
					
					if sshtest contains "ssh" and sshtest contains User then
						set secondstage to true
						tell theWindow
							set contents of text field "status" of theWindow to "stage 2 of 2 complete"
							update
						end tell
						delay 1
						exit repeat
					else
						delay 1
					end if
				end repeat
			end if
			
			---------------------------------------------------------------------------------------------
			---------------------------------------------------------------------------------------------
			
			if firststage is true then
				if secondstage is true then
					tell theWindow
						set contents of text field "status" of theWindow to "please be patient - ScreenSharing sometimes takes ages to connect"
						update
					end tell
					
					--*************** try screen share thru the tunnels ***********--
					tell application "Finder" to open location "vnc://127.0.0.1:5906"
					(*
					tell application "Finder" to get (path to me) as alias
					tell application "Finder" to get result as string -- container of result
					set desktop_alias to result & "Contents:Resources:externalDesktop.vncloc" as alias
					
					-- try to open desktop vncloc with finder, or screen sharing, or just reveal the file
					try
						tell application "Finder" to open file desktop_alias -- using (path to application "Finder")
					on error
						try
							tell application "Screen Sharing" to open file desktop_alias
						on error
							tell application "Finder" to reveal file desktop_alias
						end try
					end try
					*)
					
					--------------------------------------------------------------------------------
					--------------------------------------------------------------------------------
					
					tell application "Finder" to get (path to me) as alias
					tell application "Finder" to get result as string -- container of result
					set audio_alias to result & "Contents:Resources:externalAudio.trak" as alias
					
					-- try to open audio trak with finder, or au lab, or just reveal the file
					try
						tell application "Finder" to open file audio_alias -- using (path to application "Finder")
					on error
						try
							tell application "AU Lab" to open file audio_alias
						on error
							tell application "Finder" to reveal file audio_alias
						end try
					end try
					
				else
					tell theWindow
						set contents of text field "status" of theWindow to "timeout: stage 1 of 2 (RAS) ok, but Ranger tunnel stage failed"
						update
					end tell
				end if
			else
				tell theWindow
					set contents of text field "status" of theWindow to "timeout: stage 1 of 2 (RAS) FAILED, Ranger tunnel stage not attempted"
					update
				end tell
			end if
			
			---------------------------------------------------------------------------------------------
			---------------------------------------------------------------------------------------------			
			
			
			--******* stop the progress animation ****--
			tell theWindow
				set visible of progress indicator "progress" to true
				set uses threaded animation of progress indicator "progress" to true
				start progress indicator "progress"
			end tell
			
			---------------------------------------------------------------------------------------------
			---------------------------------------------------------------------------------------------			
			
			(*
			if accesstest then
				tell theWindow
					set contents of �class texF� "status" of theWindow to "Authentication Succeeded"
					�event coVSstoT� �class proI� "progress"
					set visible of �class proI� "progress" to false
					
				end tell
				
			else
				tell theWindow
					set contents of �class texF� "status" of theWindow to "Authentication Failed"
					�event coVSstoT� �class proI� "progress"
					set visible of �class proI� "progress" to false
					
				end tell
			end if
			
			
			tell theWindow
				-- �event coVSstoT� �class proI� "progress"
				set visible of �class proI� "progress" to false
				set visible of �class texF� "status" to true
				
				set status to contents of �class texF� "status" of theWindow
				
				set status to status & " RAS connection:"
				if sshrasdone is true then
					set status to status & " succeeded"
				else
					set status to status & " failed"
				end if
				
				set status to status & " Secondary tunnel "
				if sshdeskaudiodone is true then
					set status to status & "  succeeded"
				else
					set status to status & " failed"
				end if
				
				set contents of �class texF� "status" of theWindow to status
				�event appSfupd�
			end tell
			*)
			
			
			
			
		else if Server = "InternalTranscription" then
			
			tell theWindow
				set contents of text field "status" of theWindow to "please be patient - ScreenSharing sometimes takes ages to connect"
				update
			end tell
			
			--*************** try screen share thru the tunnels ***********--
			tell application "Finder" to open location "vnc://" & remoteIp
			(*
			tell application "Finder" to get (path to me) as alias
			tell application "Finder" to get result as string -- container of result
			set desktop_alias to result & "Contents:Resources:internalDesktop.vncloc" as alias
			
			-- try to open desktop vncloc with finder, or screen sharing, or just reveal the file
			try
				tell application "Finder" to open file desktop_alias using (path to application "Finder")
			on error
				try
					tell application "Screen Sharing" to open file desktop_alias
				on error
					tell application "Finder" to reveal file desktop_alias
				end try
			end try
			*)
			
			--------------------------------------------------------------------------------
			--------------------------------------------------------------------------------
			
			tell application "Finder" to get (path to me) as alias
			tell application "Finder" to get result as string -- container of result
			set audio_alias to result & "Contents:Resources:internalAudio.trak" as alias
			
			-- try to open audio trak with finder, or au lab, or just reveal the file
			try
				tell application "Finder" to open file audio_alias -- using (path to application "Finder")
			on error
				try
					tell application "AU Lab" to open file audio_alias
				on error
					tell application "Finder" to reveal file audio_alias
				end try
			end try
			
			(*
			tell application "Finder" to get (path to me) as alias
			tell application "Finder" to get result as string -- container of result
			set desktop_alias to result & "Contents:Resources:internalDesktop.vncloc" as alias
			
			-- try to open file with finder, or screen sharing, or just reveal the file
			try
				tell application "Finder" to open file desktop_alias -- using (path to application "Finder")
			on error
				try
					tell application "Screen Sharing" to open file desktop_alias
				on error
					tell application "Finder" to reveal file desktop_alias
				end try
			end try
			*)
			
			(*
			tell theWindow
				set visible of �class proI� "progress" to false
				set visible of �class texF� "status" to true
				set contents of �class texF� "status" of theWindow to "internal connection started "
			end tell
			*)
			
		end if -- server is external
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		
	else if name of theObject is "Disconnect" then
		set theWindow to window of theObject
		
		tell application "AU Lab" to quit
		
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
	else if name of theObject is "Initialise" then
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
					set contents of text field "netstatus" of theWindow to "UWE RAS unavailable"
					update
				end tell
			else
				tell theWindow
					set contents of text field "netstatus" of theWindow to "Network test failed"
					update
				end tell
				
			end if
		end if
		try
			do shell script "rm /private/tmp/sshtest.txt"
		end try
		
		---------------------------------------------------------------------------------------------
		---------------------------------------------------------------------------------------------
		
	else if name of theObject is "Dropbox" then
		
		--*******Collect Connection info from UI*********--
		tell theWindow
			set User to contents of text field "Username"
			set Access to contents of text field "Password"
			set ConnectionIndex to contents of button "Type"
			
			if ConnectionIndex is equal to 0 then set Server to "InternalTranscription"
			if ConnectionIndex is equal to 1 then set Server to "ExternalTranscription"
		end tell
		
		if Server is "InternalTranscription" then
			--******* Set mmini ip and ports for second tunnel thru ranger *********--
			
			tell application "Finder" to open location "afp://ppad@" & remoteIp & ":548" & remoteDropboxPath
		else if Server is "ExternalTranscription" then
			
			set finderLocation to "afp://127.0.0.1:" & fileSharingLocalPort & remoteDropboxPath
			try
				if fileSharingLocalPort is not "" then
					tell application "Finder" to open location finderLocation
				else
					display dialog "Cannot connect to remote file sharing at " & finderLocation & return & return & "Did you push the connect button?"
				end if
			on error
				display dialog "Cannot connect to remote file sharing at " & finderLocation as string
			end try
			
		end if
		
	else if name of theObject is "PHP Processing" then
		
		open location "http://www.google.com/"
		
	end if
	
end clicked

on choose menu item theObject
	-- In this Case "theObject" is the window itself
	set theWindow to the window of theObject
	
	tell theWindow
		set ConnectionIndex to contents of button "Type"
		if ConnectionIndex is equal to 0 then set Server to "InternalTranscription"
		if ConnectionIndex is equal to 1 then set Server to "ExternalTranscription"
		
		if Server is "InternalTranscription" then
			set visible of text field "Username" to false
			set visible of text field "Password" to false
			set visible of text field "UsernamePrompt" to false
			set visible of text field "PasswordPrompt" to false
		else if Server is "ExternalTranscription" then
			set visible of text field "Username" to true
			set visible of text field "Password" to true
			set visible of text field "UsernamePrompt" to true
			set visible of text field "PasswordPrompt" to true
		end if
	end tell
end choose menu item
