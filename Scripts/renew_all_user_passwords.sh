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

declare -A array
array["userA"]="userA@mydomain.com"
array["userB"]="userB@mydomain.com"
array["userC"]="userC@mydomain.com"

for i in "${!array[@]}"
do
#  echo "key  : $i"
#  echo "value: ${array[$i]}"
  user=$i
  expiry_date=$(date +'%Y-%m-01' -d 'next month')
  new_password="$(genpasswd | sort -R | awk '{printf "%s",$1}')"

psql << EOF
  set password_encryption='scram-sha-256';
  alter role $user with encrypted password '$new_password' valid until '$expiry_date';
EOF

  echo "New password for user $user: $new_password is valid until $expiry_date." |  mail -s  "DB password" -r "dba@mydomain.com" ${array[$i]}
done

exit 0
