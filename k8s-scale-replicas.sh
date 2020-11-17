#! /bin/bash -e
# Author - Andrew Milam
# This will scale resources across an entire k8s cluster up/or down


echo "Note!!! This Is Intended For Cluster Wide Draining!"
echo "Use With Caution and Dont Delete Backups Until Restored!"
echo ""
read -p  "Is this for statefulsets, or deployments? " TYPE
echo ""
export CONTEXT=$(kubectl config current-context)
scaled=$(ls|grep "$CONTEXT-scaled-$TYPE.txt")

# creates a backup of $TYPE resources deployed per a k8s cluster
make_backup() {
   kubectl get $TYPE -A -o=wide > "${CONTEXT}-scaled-$TYPE.txt"
   kubectl get $TYPE -A -o=json > "${CONTEXT}-scaled-$TYPE.json"
  jq --raw-output '.items[] | "\(.metadata.namespace)|\(.metadata.name)|\(.spec.replicas)"' "${CONTEXT}-scaled-$TYPE.json"|
   while IFS="|" read -r namespace name replicas; do
      #printf '%s|%s\n' "$namespace" "$name"
      echo ""
      echo "$TYPE/$name is ready to be scaled."
      echo ""
   done
}

# scales up resources of $TYPE to their previous state of replica count
scale_up() {
   jq --raw-output '.items[] | "\(.metadata.namespace)|\(.metadata.name)|\(.spec.replicas)"' "${CONTEXT}-scaled-$TYPE.json"|
   while IFS="|" read -r namespace name replicas; do
      #printf '%s|%s\n' "$namespace" "$name"
      echo ""
      echo "scaling $name back to $replicas in $namespace namespace"
      echo ""
      kubectl scale $TYPE/$name --namespace $namespace --replicas $replicas
      echo ""
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

   done
}

# scales down replicas of $TYPE after backup is taken
scale_down() {
jq --raw-output '.items[] | "\(.metadata.namespace)|\(.metadata.name)|\(.spec.replicas)"' "${CONTEXT}-scaled-$TYPE.json"|
   while IFS="|" read -r namespace name replicas; do
      echo ""
      echo "scaling $name down to 0 in $namespace namespace"
      echo ""
      kubectl scale $TYPE/$name --namespace $namespace --replicas 0
      echo ""
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
      echo ""
      echo "Created ${CONTEXT}-scaled-$TYPE.json and ${CONTEXT}-scaled-$TYPE.txt"
      echo "for future restoration."
      echo ""
   done
}

if [[ $scaled ]]
then
   echo "There is a backup file [$scaled] from a scale down function"
   echo ""
   echo "Do you want to scale the replicas listed in $scaled back up? "
   read -p 'Enter [y/N]: ' P1
   echo ""
   if [[ $P1 == 'y' ]]
   then
      scale_up
   fi
   if [[ $P1 == 'n' ]]
   then
      exit 0
   fi
fi

if [[ ! $scaled ]]
then
   echo "Do you want to list the $TYPE in $CONTEXT? "
   read -p "Enter [y/N]: " P1
   echo ""
   if [[ $P1 == 'y' ]]
   then
      kubectl get $TYPE -A
      echo ""
      sleep 1
      echo "Do you want to scale all $TYPE in $CONTEXT to 0? "
      read -p "Enter [y/N] " P2
      echo ""
      if [[ $P2 == 'y' ]]
      then
         make_backup
         scale_down
      fi
      if [[ $P2 == 'n' ]]
      then
         exit 0
      fi
   fi
   if [[ $P1 == 'n' ]]
   then
      exit 0
   fi
fi
