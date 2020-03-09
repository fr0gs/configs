function gc
    if test -e /usr/bin/git
	git clone $argv
    else
	echo "Git not installed."
    end
end
