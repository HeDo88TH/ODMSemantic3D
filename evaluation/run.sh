#!/bin/bash

# Download the latest release of the OPC repository
#wget https://github.com/uav4geo/OpenPointClass/releases/download/latest/opc.tar.gz
wget https://digipa.it/wp-content/uploads/opc.tar.gz
tar -xzvf opc.tar.gz
chmod +x pctrain pcclassify

# Get the list of all point cloud file paths in the datasets repository excluding the ground-truth folder
DATASET_FILES=$(find . -type f -iname "*.laz" -o -iname "*.las" -o -iname "*.ply" | grep -v "ground-truth")

echo "Dataset Files: $DATASET_FILES"

# Load training settings from settings.json
SCALES=$(jq '.scales' evaluation/settings.json)
RESOLUTION=$(jq '.resolution' evaluation/settings.json)
RADIUS=$(jq '.radius' evaluation/settings.json)

echo "SCALES: $SCALES"
echo "RESOLUTION: $RESOLUTION"
echo "RADIUS: $RADIUS"

# Step 4: Execute pctrain on all point clouds from step 2 with the settings from step 3
./pctrain --classifier gbt --scales $SCALES --resolution $RESOLUTION --radius $RADIUS --output new-model.bin $DATASET_FILES

# Checkout the ground truth repository is done in the workflow.yml

# Get the list of all point cloud file paths in the ground truth repository
GROUND_TRUTH_FILES=$(find ground-truth -type f -iname "*.laz" -o -iname "*.las" -o -iname "*.ply")

echo "Ground Truth Files: $GROUND_TRUTH_FILES"

# Execute pcclassify for each point cloud from step 6 with the new-model.bin from step 4 and stats-file new-stats.json
for FILE in $GROUND_TRUTH_FILES; do

  OUTPUT_FILE="${FILE%.*}_classified.${FILE##*.}"

  # Calculate the new-stats.json file path
  FOLDER=$(dirname $FILE)
  NEW_STATS_FILE="${FOLDER}/new-stats.json"

  ./pcclassify --regularization local_smooth --reg-radius $RADIUS --eval --stats-file $NEW_STATS_FILE $FILE $OUTPUT_FILE new-model.bin
done

# Add new-model.bin to the PR
git config --global user.email "noreply@github.com"
git config --global user.name "GitHub Actions"
git add new-model.bin
git commit -m "Add new-model.bin"
git push origin HEAD:$GITHUB_HEAD_REF