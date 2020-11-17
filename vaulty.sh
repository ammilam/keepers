#! /bin/bash -e
# Author: Andrew Milam
# Vaulty cli tool that acts as an interface to vault

# colors for formatting
RED=$(tput setaf 1) # Red
GRN=$(tput setaf 2) # Green
YLW=$(tput setaf 3) # Yellow
BLU=$(tput setaf 4) # Blue - Too dark for black background
PUR=$(tput setaf 5) # Purple
CYN=$(tput setaf 6) # Cyan
WHT=$(tput setaf 7) # White
RST=$(tput sgr0) # Text reset.
BLD=$(tput bold) # Bold

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


# ensures cli tools are installed
which yq 2>&1 >/dev/null || (echo "Error, yq executable is required" && exit 1) || exit 1
which jq 2>&1 >/dev/null || (echo "Error, jq executable is required" && exit 1) || exit 1
which vault 2>&1 >/dev/null || (echo "Error, vault executable is required" && exit 1) || exit 1


### Enterprise/program/etc specific vault paths passed in vault commands in each function ###
PROGRAM=
VL_PATH=

### roleid function ###
# lists vault role-ids for a particular environment and keyword
roleid(){
    for i in $(vault list auth/$PROGRAM/$ENV/approle/role|grep "$KEYWORD");
    do echo "${BLD}${GRN}$i${RST}: "; vault read auth/$PROGRAM/non-prod/approle/role/$i/role-id;echo ""
    done
}

### read_approle_2 function ###
# repeats prompt to the user to read more vault approles as a part of the approle flow
read_approles_2() {
  read -p "${CYN}${BLD}For which approle? ${RST}" APPROLE
  clear
  echo ""
  vault read auth/$PROGRAM/$ENV/approle/role/$APPROLE
  POLICY=$(vault read -field=token_policies auth/$PROGRAM/$ENV/approle/role/$APPROLE|sed 's/[][]//g')
  echo ""
  echo ""
  echo "${BLD}$POLICY token_policies${RST}"
  echo "---"
  vault policy read $POLICY
  echo ""
  echo "${CYN}${BLD}Would you like to read another "$KEYWORD" approle?${RST}"
  read -p "${GRN}${BLD}Enter${RST} ${BLD}[y/N]:${RST} " R1
  echo ""
  clear

  if [[ "$R1" == "y" ]]
    then
      approles
      echo ""
      read -p "${BLD}Which approle? ${RST}" APPROLE
      clear
      echo ""
      vault read auth/$PROGRAM/$ENV/approle/role/$APPROLE
      POLICY=$(vault read -field=token_policies auth/$PROGRAM/$ENV/approle/role/$APPROLE|sed 's/[][]//g')
      echo ""
      echo ""
      echo "${BLD}$POLICY token_policies${RST}"
      echo "---"
      vault policy read $POLICY
      echo ""
      echo "Would you like to read another "$KEYWORD" approle?"
      read -p "${GRN}${BD}Enter${RST} ${BLD}[y/N]:${RST} " R4
      clear
      echo ""

      if [[ -z "$R4" ]]
      then
        echo "${RED}${BLD}You did not enter a valid option.${RST}"
        select_to_return
      fi

      if [[ "$R4" == "y" ]]
      then
        read_approles_2
      fi

      if [[ "$R4" == "n" ]]
      then
        select_to_return
      fi

      if [[ -z "$R4" ]]
      then
        echo "${RED}${BLD}You did not enter a valid option.${RST}"
        clear
        read_approles_2
      fi

      if [[ ("$R4" != "y"||"n") ]]
      then
        echo "${RED}${BLD}You did not enter a valid option.${RST}"
        read_approles_2
      fi
    fi

  if [[ -z "$R1" ]]
  then
    select_to_return
  fi

  if [[ "$R1" == "n" ]]
  then
    select_to_return
  fi

  if [[ ("$R1" != "y"||"n") ]]
  then
    echo "${RED}${BLD}You did not enter a valid option.${RST}"
    read_approles_1
  fi

  if [[ -z "$R1" ]]
  then
    echo "${RED}${BLD}You did not enter a valid option.${RST}"
    read_approles_1
  fi

  if [[ ($R1 != "y"||"n") ]]
  then
    echo "${RED}${BLD}You did not enter a valid option.${RST}"
    read_approles_1
  fi

}

### read_approle_1 function ###
# initial vault approle list and read prompt
read_approles_1() {
  echo "${CYN}${BLD}Would you like to read one of the approles listed for $ENV "$KEYWORD"?${RST}"
  read -p "${GRN}${BLD}Enter${RST} ${BLD}[y/N]:${RST} "  APPROLEREAD
  echo ""

  if [[ "$APPROLEREAD" == 'y' ]]
  then
    read -p "${GRN}${BLD}Which approle?${RST} " APPROLE
    clear
    echo ""
    vault read auth/$PROGRAM/$ENV/approle/role/$APPROLE
    POLICY=$(vault read -field=token_policies auth/$PROGRAM/$ENV/approle/role/$APPROLE|sed 's/[][]//g')
    echo ""
    echo ""
    echo "${BLD}$POLICY token_policies${RST}"
    echo "---"
    vault policy read $POLICY
    echo ""
    echo "${CYN}${BLD}Would you like to read another "$KEYWORD" approle?${RST} ${BLD}[y/N]:${RST} "
    read -p "${GRN}${BLD}Enter${RST} ${BLD}[y/N]:${RST} " R1
    echo ""

    if [[ "$R1" == "y" ]]
    then
      approles
      echo ""
      read_approles_2
    fi

    if [[ -z "$R1" ]]
    then
      echo "${RED}${BLD}You did not enter a valid option.${RST}"
      clear
      read_approles_1
    fi

    if [[ "$R1" == "n" ]]
    then
      select_to_return
    fi

    if [[ ("$R1" != "y"||"n") ]]
    then
      echo "${RED}${BLD}You did not enter a valid option.${RST}"
      clear
      read_approle_1
    fi
  fi

  if [[ -z "$APPROLEREAD" ]]
  then
    echo "${RED}${BLD}You did not enter a valid option.${RST}"
    read_approles_1
  fi

  if [[ "$APPROLEREAD" == 'n' ]]
  then select_to_return
  fi

  if [[ ("$APPROLEREAD" != "y"||"n") ]]
  then
      echo "${RED}${BLD}You did not enter a valid option.${RST}"
      read_approles_1
  fi

}

### read_roleset_2 function ###
# repeats prompt to the user to read more vault rolesets as a part of the roleset flow
read_roleset_2(){
  echo ""
  read -p "${GRN}${BLD}Which roleset?${RST} " ROLESET
  echo ""
  vault read $PROGRAM/$ENV/$VL_PATH/roleset/$ROLESET
  echo ""
  echo "${CYN}${BLD}Would you like to read another roleset?"
  read -p "${GRN}${BLD}Enter${RST} ${BLD}[y/N]:${RST} " R2
  echo ""
  clear

  if [[ "$R2" == "y" ]]
    then
      rolesets
      echo ""
      read -p "${GRN}${BLD}Which roleset?${RST} " ROLESET
      echo ""
      vault read $PROGRAM/$ENV/$VL_PATH/roleset/$ROLESET
      echo "${CYN}${BLD}Would you like to read another roleset?${RST}"
      read -p "${GRN}${BLD}Enter${RST} ${BLD}[y/N]:${RST} " R3

      if [[ "$R3" == "y" ]]
      then
        read_roleset_2
      fi

      if [[ "$R3" = "n" ]]
      then
        select_to_return
      fi

      if [[ -z "$R3" ]]
      then
        select_to_return
      fi

      if [[ ("$R3" != "y"||"n") ]]
      then
        echo "${RED}${BLD}You did not enter a valid option.${RST}"
        read_roleset_2
      fi
    fi

    if [[ "$R2" == "n" ]]
    then
      select_to_return
    fi

    if [[ -z "$R2" ]]
    then
      select_to_return
    fi

    if [[ ("$R2" != "y"||"n") ]]
    then
      echo "${RED}${BLD}You did not enter a valid option.${RST}"
      read_roleset_2
    fi

}

### read_roleset_1 function ###
# initial vault roleset list and read prompt
read_roleset_1() {
  echo ""
  echo "${CYN}${BLD}Would you like to read a roleset listed for $ENV "$KEYWORD"?${RST}"
  read -p "${GRN}${BLD}Enter${RST} ${BLD}[y/N]:${RST} " ROLESETREAD
  echo ""

  if [[ "$ROLESETREAD" == 'y' ]]
  then
    read -p "${GRN}${BLD}For which roleset?${RST} "  ROLESET
    clear
    echo ""
    DATA=$(vault read $PROGRAM/$ENV/$VL_PATH/roleset/$ROLESET)
    echo "${BLD}$DATA${RST}"
    echo ""
    echo "${CYN}${BLD}Would you like to read another roleset?${RST}"
    read -p "${GRN}${BLD}Enter${RST} ${BLD}[y/N]:${RST} " R2
    echo ""

    if [[ "$R2" == "y" ]]
    then
        rolesets
        echo ""
        read_roleset_2
    fi

    if [[ "$R2" == "n" ]]
    then select_to_return
    fi

    if [[ ("$R2" != "y"||"n") ]]
    then
      echo "${RED}${BLD}You did not enter a valid option.${RST}"
      read_roleset_2
    fi
  fi

  if [[ -z "$ROLESETREAD" ]]
  then
    select_to_return
  fi

  if [[ "$ROLESETREAD" == 'n' ]]
  then
    select_to_return
  fi

  if [[ ("$ROLESETREAD" != "y"||"n") ]]
  then
    echo "${RED}${BLD}You did not enter a valid option.${RST}"
    read_roleset_1
  fi
}

### approles funtion ###
# lists vault approles per an environment and keyword
approles() {

  if [[ -z "$KEYWORD" ]]
  then
    clear
    echo ""
    DATA=$(vault list auth/$PROGRAM/$ENV/approle/role)
    echo "${BLD}$DATA${RST}"
  fi

  if [[ ! "$KEYWORD" == "" ]]
  then
    clear
    echo ""
    DATA=$(vault list auth/$PROGRAM/$ENV/approle/role|grep "$KEYWORD")
    echo "${BLD}$DATA${RST}"
  fi

}

### rolesets function ###
# lists vault rolesets per an environment and keyword
rolesets() {

  if [[ -z "$KEYWORD" ]]
  then
    clear
    echo ""
    DATA=$(vault list $PROGRAM/$ENV/$VL_PATH/rolesets)
    echo "${BLD}$DATA${RST}"
  fi

  if [[ ! "$KEYWORD" == "" ]]
  then
    clear
    echo ""
    DATA="${BLD}$(vault list $PROGRAM/$ENV/$VL_PATH/rolesets|grep "$KEYWORD")${RST}"
    echo "${BLD}$DATA${RST}"
  fi

}

create_alias() {

  if [[ $(cat $FILE|grep vaulty) == "alias vaulty='${SCRIPT_DIR}/$SCRIPT_NAME'" ]]
  then
    echo "${RED}${BLD}vaulty alias already exists${RST}"
  fi

  if [[ $(cat $FILE|grep vaulty) != "alias vaulty='${SCRIPT_DIR}/$SCRIPT_NAME'" ]]
  then
    if [[ -f ~/.bash_profile ]]
    then
      FILE=~/.bash_profile
      echo -e -n "\nalias vaulty='${SCRIPT_DIR}/$SCRIPT_NAME'" >> $FILE
      echo "${BLD}vaulty alias created${RST}"
      echo "${BLD}When done, dont forget to run"
      echo "${YLW}source $FILE${RST}"
      echo "${BLD}to load the alias.${RST}"
    fi
    if [[ ! -f ~/.bash_profile ]]

    then
      FILE=~/.bashrc
      echo -e -n "alias vaulty='${SCRIPT_DIR}/$SCRIPT_NAME'" >> $FILE
      echo "${BLD}vaulty alias created${RST}"
      echo "${BLD}When done, dont forget to run"
      echo "${YLW}source $FILE${RST}"
      echo "to load the alias."
    fi
  fi
}
### keyword function ###
# prompt for keyword to fill KEYWORD variable with
# passed to all the other functions to build list queries for various vault resources
keyword() {
  echo "${CYN}${BLD}For what keyword?${RST} ${BLD}[examples: orders/coding/facilities/patients/dashboard/ccmt]${RST} "
  read -p "${GRN}${BLD}Enter a keyword or hit enter to list all: ${RST}" KEYWORD
}

### env function ###
# prompt for prod/non-prod to fill ENV variable with
# passed to all other functions to build list queries for environment specific vault resources
env(){
  echo "${CYN}${BLD}Do you want to list $ITEM for prod or non-prod?${RST}"
  read -p "${GRN}${BLD}Enter${RST} ${BLD}[prod/NON-PROD]: ${RST}" ENV

  if [[ -z "$ENV" ]]
  then
    ENV=non-prod
  fi

  echo ""
}

### auth function ###
# prompts user for a keyword to use as a search parameter in vault auth list command
auth_path() {
  echo "${CYN}${BLD}What keyword would you like to search for in the vault auth paths?${RST}"
  read -p "${GRN}${BLD}Enter a keyword or hit enter to show all:${RST} "  KEYWORD

  if [[ -z ""$KEYWORD"" ]]
  then
    echo "${BLD}$(vault auth list)${RST}"
  fi

  if [[ ! -z ""$KEYWORD"" ]]
  then
    echo "${BLD}$(vault auth list)${RST}"
  fi

}

### first function ###
# initial function selection prompt and return prompt for when users go through a flow that triggers select_to_return()
first() {
  clear
  echo "${BLD}${PUR}
____   ____            .__   __
\   \ /   /____   __ __|  |_/  |_ ___.__.
 \   Y   /\__  \ |  |  \  |\   __<   |  |
  \     /  / __ \|  |  /  |_|  |  \___  |
   \___/  (____  /____/|____/__|  / ____|
               \/                 \/
${RST}"
  echo "${BLD}${CYN}Make a selection: ${RST}"
  echo ""
  echo "${BLD}1) List and read approles in prod/non-prod for a particular keyword"
  echo "2) List role_ids in prod/non-prod for a particular keyword"
  echo "3) List, read, and decode SA keys per a given lease in prod/non-prod for a particular keyword"
  echo "4) List and read rolesets in prod/non-prod for a particular keyword"
  echo "5) Search for vault auth paths per a given keyword"
  echo "6) Install vaulty as an alias"
  echo ""
  read -p "${GRN}Enter${RST} ${BLD}[1/2/3/4/5/6]: ${RST}" P1
  echo ""
}

### VAULT AUTH ###
# Checks if user has vault token and if it is valid. If it doesnt, the user is prompted to login
vault_auth() {
export EXIT_CODE=$(vault token lookup > /dev/null 2>&1|| echo $?)

if [[ "$EXIT_CODE" == 2 ]]
then

echo "${BLD}${PUR}
____   ____            .__   __
\   \ /   /____   __ __|  |_/  |_ ___.__.
 \   Y   /\__  \ |  |  \  |\   __<   |  |
  \     /  / __ \|  |  /  |_|  |  \___  |
   \___/  (____  /____/|____/__|  / ____|
               \/                 \/
${RST}"
  export VAULT_ADDR="" # enter in vault address
  echo "${RED}Your vault token is invalid and you need to reauthenticate.${RST}"
  vault login -method=ldap
  sleep 2
  clear
  first
fi

if [[ -z "$EXIT_CODE" ]]
then
  first
fi
}

### lease function ###
# returns a list of vault key leases per an environment
lease() {
  for i in $(vault list  sys/leases/lookup/|sed '1,2d'); do echo ${BLD}${i%/}${RST};
  done
  echo ""
  read -p "${CYN}${BLD}For which path?${RST} " VLPATH
  echo ""
  if [[ "$VLPATH" != "$VL_PATH" ]]
  then
    DATA=$(vault list sys/leases/lookup/$VLPATH/)
    echo "${BLD}${DATA}${RST}|grep -v /"

  fi

  # VL_PATH specific path and supporting logic
  if [[ "$VLPATH" == "$VL_PATH" ]]
  then
    for i in $(vault list sys/leases/lookup/$VLPATH/$ENV/gcp/key); do echo ${BLD} ${i%/} ${RST}; done
    echo ""
    echo "${CYN}${BLD}Would you like to read a lease?${RST}"
    read -p "${GRN}${BLD}Enter [y/N]: ${RST}" P5
    echo ""

    if [[ "$P5" == "y" ]]
    then
      read -p "${GRN}${BLD}For which lease?${RST} " RLEASE
      echo ""
      echo "${BLD}Here are the keys for $RLEASE:${RST}"
      echo ""
      for i in $(curl -s -H "X-Vault-Token: $(vault print token)" -H "X-Vault-Request: true" $VAULT_ADDR/v1/sys/leases/lookup/$VLPATH/$ENV/gcp/key/$RLEASE?list=true|jq -c '.data.keys')
      do
        for t in $(echo ${i[@]}| jq -r  '.[]'); do
        LEASE_ID="$(echo $VLPATH/$ENV/gcp/key/$RLEASE/$t)"
        curl -s --location --request PUT "$VAULT_ADDR/v1/sys/leases/lookup" --header "X-Vault-Token: $(vault print token)" --header 'Content-Type: application/json' --data-raw "{\"lease_id\": \"$LEASE_ID\"}"| jq -r '.data'| yq read - --prettyPrint; echo ""; done
        echo ""
        echo "${CYN}${BLD}Would you like to base64 decode the private_key_data for $RLEASE?${BLD}${RST}"
        read -p "${GRN}${BLD}Enter:${RST} ${BLD}[y/N]${RST} " LER
        echo ""
        done

        if [[ "$LER" == "y" ]]
        then
          DATA=$(vault read $VLPATH/$ENV/gcp/key/$RLEASE/ -format=json|jq  -r '.data.private_key_data' |base64 --decode)
          echo "${BLD}$DATA${RST}"
          echo ""
          echo ""
          read -p "${BLD}${RED}Press enter to continue${RST}"

          clear
          select_to_return
        fi

        if [[ "$LER" == "n" ]]
        then
          select_to_return
        fi

        if [[ -z "$LER" ]]
        then
          select_to_return
        fi

        if [[ ("$LER" != "y"||"n") ]]
        then
          echo "${RED}${BLD}You did not enter a valid option.${RST}"

          clear
          select_to_return
        fi
    fi

    if [[ "$P5" == "n" ]]
    then
      select_to_return
    fi

    if [[ -z "$P5" ]]
    then
      select_to_return
    fi

    if [[ ("$P5" != "y"||"n") ]]
    then
      echo "${RED}${RED}You did not enter a valid option.${RST}"
      clear

      select_to_return
    fi
  fi

  if [[ "$VLPATH " != "$VL_PATH" ]]
  then
    select_to_return
  fi

}

### select_to_return function ###
# prompts user if they want to return to the beginning of the script to make more selections
select_to_return(){
  echo ""
  echo "${GRN}${BLD}Do you want to make another selection?${RST} "
  read -p "${GRN}${BLD}Enter${RST} ${BLD}[y/N]:${RST} " SELECT

  if [[ "$SELECT" == "y" ]]
  then
    clear
    exec bash "$0" "$@"
  fi

  if [[ -z "$SELECT" ]]
  then
    exit 1
  fi

  if [[ "$SELECT" == "n" ]]
  then exit 1
  fi

  if [[ ("$SELECT" != "y"||"n") ]]
  then
    echo "${RED}${BLD}You did not enter a valid option.${RST}"

    select_to_return
  fi

}

vault_auth

### approles flow ###
if [[ "$P1" == 1 ]]
then
  ITEM=approles
  env

  if [[ ! "$ENV" =~ ^(prod|non-prod)$ ]]
  then
    echo "${RED}${BLD}You did not enter a valid option.${RST}"
    echo ""

    env
  fi

  keyword
  echo ""
  approles
  echo ""
  read_approles_1
  select_to_return
fi


### role_ids flow ###
if [[ "$P1" == 2 ]]
then
  ITEM=role_ids
  env

  if [[ ! "$ENV" =~ ^(prod|non-prod)$ ]]
  then
    echo "${RED}${BLD}You did not enter a valid option.${RST}"
    echo ""

    env
  fi

  read -p "${CYN}${BLD}For what keyword?${RST} ${BLD}[examples: orders/coding/facilities/patients/dashboard/ccmt]${RST} " KEYWORD

  if [[ -z ""$KEYWORD"" ]]
  then
    echo "${RED}${BLD}You must enter a keyword for role_ids.${RST}"
    select_to_return
  fi

  echo ""
  roleid
  select_to_return
fi

### leases flow ###
if [[ "$P1" == 3 ]]
then
  ITEM=leases
  env

  if [[ ! "$ENV" =~ ^(prod|non-prod)$ ]]
  then
    echo "${RED}${BLD}You did not enter a valid option.${RST}"
    echo ""

    env
  fi
  lease
  select_to_return
fi

### rolesets flow ###
if [[ "$P1" == 4 ]]
then
  ITEM=rolesets
  env
  if [[ ! "$ENV" =~ ^(prod|non-prod)$ ]]
  then
    echo "${RED}${BLD}You did not enter a valid option.${RST}"
    echo ""

    env
  fi
  echo ""
  keyword
  rolesets
  read_roleset_1
  select_to_return
fi


### auth flow ###
if [[ "$P1" == 5 ]]
then
  ITEM=auth
  auth_path
  select_to_return
fi

if [[ "$P1" == "6" ]]
then
  if [[ -f ~/.bash_profile ]]
  then
    FILE=~/.bash_profile
    source ~/.bash_profile
  fi

  if [[ ! -f ~/.bash_profile ]]
  then
    FILE=~/.bashrc
    source ~/.bashrc
  fi
  create_alias
  select_to_return
fi

### VALIDATION LOGIC ###
# ensures proper entry of expected responses to prompts
if [[ "$SELECT" == "y" ]]
then exec bash "$0" "$@"
fi

if [[ "$SELECT" == "n" ]]
then exit 1
fi

if [[ ! "$P1" =~ ^(1|2|3|4|5|6)$ ]]
then
    echo "${RED}${BLD}You did not enter a valid option.${RST}"
    exec bash "$0" "$@"
fi

if [[ -z "$P1" ]]
then
    echo "${RED}${BLD}You did not enter a valid option.${RST}"
    exec bash "$0" "$@"

fi

if [[ ("$READ" != "y"||"n") ]]
then
    echo "${RED}${BLD}You did not enter a valid option.${RST}"
    echo ""
    exec bash "$0" "$@"
fi

if [[ (""$ROLESETREAD"" != "y"||"n") ]]
then
    echo "${RED}${BLD}You did not enter a valid option.${RST}"
    echo ""
    exec bash "$0" "$@"
fi
