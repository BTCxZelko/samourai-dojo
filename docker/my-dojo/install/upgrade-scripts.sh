#!/bin/bash

# Confirm upgrade operation
get_confirmation() {
  while true; do
    echo "This operation is going to upgrade your Dojo to v$DOJO_VERSION_TAG."
    read -p "Do you wish to continue? [y/n]" yn
    case $yn in
      [Yy]* ) return 0;;
      [Nn]* ) echo "Upgrade was cancelled."; return 1;;
      * ) echo "Please answer yes or no.";;
    esac
  done
}

# Update configuration files from templates
update_config_files() {
  if [ -f ../../db-scripts/1_db.sql ]; then
    rm ../../db-scripts/1_db.sql
    echo "Deleted 1_db.sql"
  fi

  cp ../../db-scripts/2_update.sql.tpl ../../db-scripts/2_update.sql
  echo "Initialized 2_update.sql"

  update_config_file ./conf/docker-bitcoind.conf ./conf/docker-bitcoind.conf.tpl
  echo "Initialized docker-bitcoind.conf"

  update_config_file ./conf/docker-mysql.conf ./conf/docker-mysql.conf.tpl
  echo "Initialized docker-mysql.conf"

  update_config_file ./conf/docker-node.conf ./conf/docker-node.conf.tpl
  echo "Initialized docker-node.conf"
}

# Update a configuration file from template
update_config_file() {
  sed "/^#.*/P;s/=.*//g;/^$/d" $1 > ./original.raw
  sed "/^#.*/P;s/=.*//g;/^$/d" $2 > ./tpl.raw
  grep -vf ./original.raw ./tpl.raw > ./newvals.dat

  cp -p $1 "$1.save"

  echo "
  " >> $1

  grep -f ./newvals.dat $2 >> $1

  rm ./original.raw
  rm ./tpl.raw
  rm ./newvals.dat
}

# Update dojo database
update_dojo_db() {
  docker exec -d db /update-db.sh
}