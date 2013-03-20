all:
	osacompile -o iTermRestore.app iTermRestore.applescript
	cp iTermRestore.icns iTermRestore.app/Contents/Resources/applet.icns

clean:
	rm -rf iTermRestore.app
