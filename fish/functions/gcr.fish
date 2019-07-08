function gcr
    if test -e /usr/bin/git
	git checkout -b $argv remotes/origin/{$argv}
    else
	echo "Git not installed."
    end
end
