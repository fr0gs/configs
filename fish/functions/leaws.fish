function leaws --argument profile --description="Load environment variables from aws based on the profile specified."
    # Set the aws binary path into a variable
    set -l awsbinary /usr/local/bin/aws
    if test -e $awsbinary
        if set -q profile
            set -gx AWS_ACCESS_KEY_ID (aws configure --profile $profile get aws_access_key_id)
            set -gx AWS_SECRET_ACCESS_KEY (aws configure --profile $profile get aws_secret_access_key)
            set -gx AWS_DEFAULT_REGION (aws configure --profile $profile get region)
        else
            set -gx AWS_ACCESS_KEY_ID (aws configure get aws_access_key_id)
            set -gx AWS_SECRET_ACCESS_KEY (aws configure get aws_secret_access_key)
            set -gx AWS_DEFAULT_REGION (aws configure get region)
        end
    else
	    echo "aws cli not installed"
    end
end
