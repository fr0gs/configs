#!/usr/bin/fish

# User defined functions
# Upload a single file to hostalia own hosting
function upload_hostalia
	if test (count $argv) -lt 1
		echo "\$ upload_hostalia <file_to_upload>"
	else
		if not test -e /usr/bin/lftp
			echo "Error: install lftp"
		else
			set file $argv[1]
			echo -n "user: "
			read user
			echo -n "password: "
			read-password password
			lftp -c "set ftp:ssl-allow no; open -u $user,$password ftp://ftp.<search this number in your doc esteban>.srv-hostalia.com/; put -O /webspace/httpdocs/estebansastre.com $file; bye"
		end
	end
end
