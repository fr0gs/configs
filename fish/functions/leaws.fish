# Load environment variables from aws based on the
# profile specified.
function leaws
    # Set the aws binary path into a variable
    set -l awsbinary /usr/local/bin/aws
    if test -e $awsbinary
        if set -q $argv
            set -x AWS_ACCESS_KEY_ID (aws configure get aws_access_key_id)
            set -x AWS_SECRET_ACCESS_KEY (aws configure get aws_secret_access_key)
            set -x AWS_DEFAULT_REGION (aws configure get region)        
        else
            set -x AWS_ACCESS_KEY_ID (aws configure --profile $argv get aws_access_key_id)
            set -x AWS_SECRET_ACCESS_KEY (aws configure --profile $argv get aws_secret_access_key)
            set -x AWS_DEFAULT_REGION (aws configure --profile $argv get region)
        end
    else
	    echo "aws cli not installed"
    end
end
