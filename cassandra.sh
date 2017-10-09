#!/usr/bin/env bash

# A script to install cassandra modified by Anthony Spiteri for vCloud Director Metric Database installs

# ADD SEE NODES HERE - FOR SUPPORTED INSTALL 4 NODES WITH 2 SEEDS REQUIRED
SEEDS[0]='172.17.0.10'
#SEEDS[1]=172.17.0.11'
#SEEDS[2]=172.17.0.12'
#SEEDS[3]=172.17.0.13'

containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

function join { local IFS="$1"; shift; echo "$*"; }

# INSTALL JAVA
apt-get -y install default-jre
apt-get -y install default-jdk
update-alternatives --config java
sudo sh -c "echo 'JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java"' >> /etc/environment "
source /etc/environment

# INSTALL JNA
apt-get -y install libjna-java

# ADD CASSANDRA REPOS TO APT
curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
echo "deb http://debian.datastax.com/community stable main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
apt-get update
 
# INSTALL AND START CASSANDRA 2.2.6
apt-get -y install cassandra=2.2.6
apt-get -y install cassandra-tools=2.2.6

sudo service cassandra stop
sudo rm -rf /var/lib/cassandra/data/system/*

# EXTRACT IP ADDRESS OF ENS160
IP_ADDR=`/sbin/ifconfig ens160 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`

# UPDATE CASSANDRA CONFIG
sudo sed -i "s/cluster_name: 'Test Cluster'/cluster_name: 'vCloud Director Metric Cluster'/g" /etc/cassandra/cassandra.yaml
sudo sed -i 's/authenticator: AllowAllAuthenticator/authenticator: PasswordAuthenticator/g' /etc/cassandra/cassandra.yaml
ALL_SEEDS=`join , ${SEEDS[@]}`
sudo sed -i 's/- seeds: "127.0.0.1"/- seeds: "'${ALL_SEEDS[@]}'"/g' /etc/cassandra/cassandra.yaml

if [[ ${SEEDS[*]} =~ $IP_ADDR ]]; then
  # settings for seed node
  sudo sed -i 's/listen_address: localhost/listen_address: '${IP_ADDR}'/g' /etc/cassandra/cassandra.yaml
  sudo sed -i 's/rpc_address: localhost/rpc_address: '${IP_ADDR}'/g' /etc/cassandra/cassandra.yaml
  sudo sh -c "echo 'auto_bootstrap: false' >> /etc/cassandra/cassandra.yaml "
else
  # settings for other nodes
  sudo sed -i 's/listen_address: localhost/listen_address: '${IP_ADDR}'/g' /etc/cassandra/cassandra.yaml
  sudo sed -i 's/rpc_address: localhost/rpc_address: '${IP_ADDR}'/g' /etc/cassandra/cassandra.yaml
fi

sudo service cassandra stop
sudo rm -rf /var/lib/cassandra/data/system/*
sudo service cassandra start
