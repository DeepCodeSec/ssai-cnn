#!/bin/bash

if [ -e ./data ]; then
    read -p "[!] There's already a /data directory. Overwrite? [Y/n]" -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
	echo "[=] Setting up sample dataset..."
	tar -C . -xvf ./dataset/sample.tar.gz 2>&1 >> /dev/null
    else
	echo "[!] Using current dataset."
    fi
fi

echo "[=] Creating dataset..."
python3 ./scripts/create_dataset.py --dataset buildings
echo "[=] Dataset creation script returned exit code '$?'."

echo "[=] Testing dataset..."
python3 ./tests/test_dataset.py \
    --ortho_db ./data/mass_buildings/lmdb/train_sat \
    --label_db ./data/mass_buildings/lmdb/train_map \
    --out_dir ./data/mass_buildings/patch_test
echo "[=] Dataset testing script returned exit code '$?'."

echo "[=] Testing transforms..."
python ./tests/test_transform.py \
    --ortho_db data/mass_buildings/lmdb/train_sat \
    --label_db data/mass_buildings/lmdb/train_map \
    --out_dir data/mass_buildings/trans_test
echo "[=] Transform testing script returned exit code '$?'."
