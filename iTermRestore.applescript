#--------------------------------------------------------------#
# Helper routines
#--------------------------------------------------------------#


# Sub-routine to split a string with a given delimiter
to splitString(aString, delimiter)
	set retVal to {}
	set prevDelimiter to AppleScript's text item delimiters
	#log delimiter
	set AppleScript's text item delimiters to {delimiter}
	set retVal to every text item of aString
	set AppleScript's text item delimiters to prevDelimiter
	return retVal
end splitString


# Sub-routine for trimming unwanted characters from strings.
# Taken from http://www.macosxautomation.com
on trim_line(this_text, trim_chars, trim_indicator)
	-- 0 = beginning, 1 = end, 2 = both
	set x to the length of the trim_chars
	-- TRIM BEGINNING
	if the trim_indicator is in {0, 2} then
		repeat while this_text begins with the trim_chars
			try
				set this_text to characters (x + 1) thru -1 of this_text as string
			on error
				-- the text contains nothing but the trim characters
				return ""
			end try
		end repeat
	end if
	-- TRIM ENDING
	if the trim_indicator is in {1, 2} then
		repeat while this_text ends with the trim_chars
			try
				set this_text to characters 1 thru -(x + 1) of this_text as string
			on error
				-- the text contains nothing but the trim characters
				return ""
			end try
		end repeat
	end if
	return this_text
end trim_line


#--------------------------------------------------------------#
# Read servers configuration
#--------------------------------------------------------------#


set serverdetails to {}
set moshserver to ""
set configFile to POSIX file ((POSIX path of (path to home folder)) & ".iTermServers")
open for access configFile
set configContents to read configFile using delimiter {linefeed}
close access configFile
repeat with config in configContents
	if character 1 of config is not "#" then
		# Check if there is a trailing comment in the line
		set config to item 1 of my splitString(config, "#")
		# Trim whitespace at the end of the config line
		set config to trim_line(config, linefeed, 1)
		set config to trim_line(config, " ", 1)
		if config starts with "moshserver" then
			# Check if the config line is for the moshserver
			set moshserver to item 2 of my splitString(config, "=")
		else
			# config line must indicate server to connect to
			# Split config line into individual config fields
			set conf to my splitString(config, ",")
			set end of serverdetails to conf
		end if
	end if
end repeat


#--------------------------------------------------------------#
# Launch iTerm and connect to servers
#--------------------------------------------------------------#


# Check if iTerm is already open.
# If so, we create a new terminal window.
# Otherwise, we use the terminal window created when iTerm is launched.
tell application "System Events"
	if "iTerm" is not in name of processes then
		launch application "iTerm"
		set iTerm_already_open to false
	else
		set iTerm_already_open to true
	end if
end tell


# If we just launched iTerm, we ignore the session that is created by default.
# We use the default terminal, but we don't use the first session that is created.
if not iTerm_already_open then
	tell application "iTerm"
		activate
		set myterm to current terminal
		set mysession to current session of current terminal
		tell i term application "iTerm" to tell mysession
			write text "echo This tab can be closed. Nothing will be displayed here through the AppleScript"
		end tell
	end tell
else
	tell application "iTerm"
		set myterm to (make new terminal)
	end tell
end if


#--------------------------------------------------------------#
# Connect to central moshserver and
# ssh to individual servers
#--------------------------------------------------------------#


# For each server in the list, we create a session in our terminal
# If the screen session for the server already exists, we just attach to it
# Otherwise, we create a new screen session and connect to the server
tell application "iTerm" to tell myterm
	set mysessions to {}


	# Create mosh connections to central moshserver for each server in the list
	repeat with details in serverdetails
		set server to item 1 of details
		set _sessionname to item 3 of details
		set _session to (launch session "Default Session")
		tell _session
			# Set the title of the iTerm tab
			set name to _sessionname
			write text "mosh " & moshserver
		end tell
		set end of mysessions to _session
		# This delay prevents multiple mosh commands from overwhelming the server
		delay 0.5

	end repeat


	# Wait for the mosh connections to succeed
	set delaytime to (count of serverdetails) + 1
	if delaytime < 6 then
		set delaytime to 6
	end if
	delay delaytime


	# Attach to existing screen sessions or create new ones as required
	set ind to 0
	repeat with details in serverdetails
		set ind to ind + 1
		set server to item 1 of details
		set _screenname to item 2 of details
		set _sessionname to item 3 of details
		set _session to item ind of mysessions
		tell _session
			# Set the title of the iTerm tab again (iTerm has poor memory of names)
			set name to _sessionname
			# Attach to screen session as appropriate
			write text "screen -ls | grep " & _screenname
			write text "if [ $? -eq 0 ]; then"
			write text "	_fullscreenname=`screen -ls | grep " & _screenname & " | awk '{print $1}'`"
			write text "	echo success; screen -d -r $_fullscreenname;"
			write text "else"
			if server is equal to moshserver then
				write text "	echo fail; screen -S " & _screenname & ";"
			else
				write text "	echo fail; screen -S " & _screenname & " ssh " & server & ";"
			end if
			write text "fi"
		end tell
		# This delay prevents multiple screen commands from attaching to same session
		delay 0.1
	end repeat
end tell
