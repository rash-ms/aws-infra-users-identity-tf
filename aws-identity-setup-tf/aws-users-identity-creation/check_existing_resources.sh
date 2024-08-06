#!/bin/bash

IDENTITY_STORE_ID=$1
USER=$2
GROUP=$3

# Check for users
if [ ! -z "$USER" ]; then
  USER_EXISTS=$(aws identitystore list-users --identity-store-id $IDENTITY_STORE_ID --filter "UserName eq '$USER'" --query "Users | length(@)" --output text)
  if [ "$USER_EXISTS" -gt 0 ]; then
    echo "User $USER exists"
    touch "user_exists_$USER"
  else
    echo "User $USER does not exist"
  fi
fi

# Check for groups
if [ ! -z "$GROUP" ]; then
  GROUP_EXISTS=$(aws identitystore list-groups --identity-store-id $IDENTITY_STORE_ID --filter "DisplayName eq '$GROUP'" --query "Groups | length(@)" --output text)
  if [ "$GROUP_EXISTS" -gt 0 ]; then
    echo "Group $GROUP exists"
    touch "group_exists_$GROUP"
  else
    echo "Group $GROUP does not exist"
  fi
fi
