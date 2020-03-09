function gcm
    if test -e /usr/bin/git
	git commit $argv
    else
	echo "Git not installed."
    end
end
