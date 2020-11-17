#! /bin/bash
# Author Andrew Milam
# Generates dashboard json files from Google Cloud Dashboards

read -p 'Enter a file name for the dashboard.json: ' FILE_NAME
read -p 'GCP Project ID: ' PROJECT_NUMBER
echo 'For which Dashboard?'
echo ""
for i in $(gcloud monitoring dashboards list|yq r - 'name'); do
echo $i; done
echo ""
read -p 'Enter a dashboard name: ' DASHBOARD_ID
# creates file
gcloud monitoring dashboards describe \
$DASHBOARD_ID --format=json > ./"${FILE_NAME}.json"