#! /bin/sh

# this generatess a configmap for a grafana dashboard json file
## once the configmap yaml is generated and saved, flux will sync it into the environment
URL=
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RED=$(tput setaf 1) # Red
GRN=$(tput setaf 2) # Green
YLW=$(tput setaf 3) # Yellow
BLU=$(tput setaf 4) # Blue - Too dark for black background
PUR=$(tput setaf 5) # Purple
CYN=$(tput setaf 6) # Cyan
WHT=$(tput setaf 7) # White
RST=$(tput sgr0) # Text reset.
BLD=$(tput bold) # Bold

usage() {
   cat <<USAGE
${BLD}At runtime, you must specify if the dashboard needs to be pulled from the Grafana API or an exported dashboard.${RST}
Usage:

./$SCRIPT_NAME ${GRN}api${RST}|${GRN}file${RST}

${BLD}Once a selection is made it will prompt for input for either a ${RED}dashboard UID${RST} ${BLD}or the path to a ${RED}dashboard.json${RST} ${BLD}file.
USAGE
}


[[ -z "$1" || "$1" =~ ^(-h|--help)$ ]] && usage && exit 1


if [[ $1 == api ]]
then
   read -p 'Dashboard UID: ' uid
   NAME=$(curl "$URL/api/dashboards/uid/$uid/"| jq -r '.dashboard.title'| awk '{print tolower($0)'})
   curl "$URL/api/dashboards/uid/$uid/"|jq 'del(.meta)' > "${NAME}.json"
   kubectl create configmap $NAME --namespace=-prometheus --from-file=./"${NAME}.json" --dry-run=true -o yaml > "${NAME}.yaml"
   rm "./${NAME}.json"
   echo "Generated: ${NAME}.yaml"
   echo "Don't forget to commit and push your changes!"
   exit 1
fi

if [[ $1 == file ]]
then
   read -p 'Enter the path to the dashboard json: ' LOC
   NAME=${LOC##*/}
   A=${NAME%.json}
   kubectl create configmap $A --namespace=-prometheus --from-file=$LOC --dry-run=true -o yaml > "${A}.yaml"
   echo "Generated: ${A}.yaml"
   echo "Don't forget to clean up the dashboard json file before committing!"
   exit 1
fi
if [[ "$1" != "api" || "$1" != "file" ]]
then
   echo "You did not enter a valid option. Enter either api or file."
fi