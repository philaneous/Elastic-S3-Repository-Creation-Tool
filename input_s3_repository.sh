#!/bin/bash

echo "######################################################################################"
echo "# This is a script to input all the variables for creating a repository via s3       #"
echo "#                                                                                    #"
echo "# Phil Bendeck | Cloudian Professional Services 2020                                 #"
echo "#                                                                                    #"
echo "######################################################################################"
echo

read -p "--> Enter the username for elasticsearch [elastic]: " user
user=${user:-elastic}
echo "--> The username = $user"
read -s -p "--> Enter the password for $user: " password
echo
read -p "--> Enter the repository name: " repository_name
echo "--> The repository name entered = $repository_name"
read -p "--> Enter bucket name: " bucket
echo "--> The bucket name = $bucket"
read -p "--> Enter the client [cloudians3]: " client
client=${client:-cloudians3}
echo "--> The client name = $client"
read -p "--> Enter the endpoint for $client: " endpoint
endpoint=${endpoint:-s3-region2.iphilsanity.com}
echo "--> The endpoint = $endpoint"
read -p "--> Enter the Protocol [https]: " protocol
protocol=${protocol:-https}
echo "--> The protocol = $protocol"
read -p "--> Enter the base path for $endpoint/$bucket: " base_path
echo "--> The base_path = $base_path"
read -p "--> Enter the FQDN of the Elasticsearch node that will register $repository_name to $endpoint/$bucket/$base_path : " fqdn
fqdn=${fqdn:-esnode1}
echo "--> The FQDN = $fqdn"

curl -u $user:$password -X PUT "$fqdn:9200/_snapshot/$repository_name?pretty" -H 'Content-Type: application/json' -d'
{
  "type": "s3",
  "settings": {
    "bucket": "'"$bucket"'",
    "client": "'"$client"'",
    "endpoint": "'"$endpoint"'",
    "protocol": "'"$protocol"'",
    "base_path": "'"$base_path"'"
  }
}
'

echo "--> Verifying $repository_name"
curl -u $user:$password -X POST "$fqdn:9200/_snapshot/$repository_name/_verify?pretty"

while true; do
    read -p "Do you want to create a snapshot on $fqdn/$repository_name? [Yes or No]: " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

read -p "--> Enter the name of the snapshot: " snapshot
echo "--> The name of the snapshot entered = $snapshot"
echo "--> Creating $snapshot = $fqdn:9200/_snapshot/$repository_name/$snapshot" 
curl -u $user:$password -X PUT "$fqdn:9200/_snapshot/$repository_name/$snapshot?wait_for_completion=true&pretty"

echo "--> Outputting $snapshot info:"
curl -u $user:$password -X GET "http://$fqdn:9200/_snapshot/$repository_name/$snapshot?pretty"

echo
echo "--> Outputting all Elasticsearch Repositories"
curl -u $user:$password -X GET "http://$fqdn:9200/_snapshot/_all?pretty"
