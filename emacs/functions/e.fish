function e
	if test -e /usr/bin/emacs
		emacs -mm $argv &
	else
		echo "Emacs not installed, try: https://launchpad.net/~kelleyk/+archive/ubuntu/emacs"
	end
end
