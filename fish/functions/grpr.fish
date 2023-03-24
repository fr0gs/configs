function grpr
    if test -e /usr/bin/git
        git fetch upstream pull/{$argv}/head:remote-pr-{$argv}
	    git checkout remote-pr-{$argv}
    else
	    echo "Git not installed."
    end
end
