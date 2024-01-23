#!/usr/bin/env bash

# Password length is 32 minus the 4 calls to choose() in  genpasswd().
# Since we do not choose randomness, we call choose() with forced input to be sure to have at least:
# - 1 special character
# - 1 number
# - 1 lower case
# - 1 upper case

PASSWORD_LENGTH=28

# Choose one character randomly from a string.
choose() { echo ${1:RANDOM%${#1}:1} $RANDOM; }

# 
genpasswd() {
  choose '!@#$%^\&'
  choose '0123456789'
  choose 'abcdefghijklmnopqrstuvwxyz'
  choose 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  for i in $( seq 1 $PASSWORD_LENGTH)
    do
      choose '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#%^\&'
    done
} 

user=$1
expiry_date=$2
new_password="$(genpasswd | sort -R | awk '{printf "%s",$1}')"

if [ $# -ne 2 ]
  then
    echo "USAGE: ./new_password.sh username expiry_date"
    echo ""
    echo "Example: ./new_password.sh userX 2022-09-30"
    echo ""
    exit -1
fi

psql << EOF
set password_encryption='scram-sha-256';
alter role $user with encrypted password '$new_password' valid until '$expiry_date';
EOF

echo "New password for user $1: $new_password is valid until $2."

exit 0
