iTerm2-restore
===================

Save iTerm sessions using a moshserver and screen

AppleScript that allows iTerm2 sessions to be saved and completely recovered by
running all terminals on a remote moshserver.

##Dependencies##

1. mosh-client must be installed on the Mac OS X machine.
2. mosh-server must be installed on the remote machine (moshserver) that we will
   login to and save terminal state.
3. GNU screen must be installed on the moshserver machine.

##Installation and Usage##

1. Run make.
2. Copy the .iTermServers file to your home directory.
3. Edit the .iTermServers file to specify the moshserver to connect to and
   provide the names or IP addresses of servers to connect to.
4. Move iTermRestore.app to any location (eg. Desktop)
5. Run the application by double clicking iTermRestore.app
