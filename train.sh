#!/bin/bash

CHAINER_TYPE_CHECK=0 CHAINER_SEED=$1 \
nohup python ./scripts/train.py \
--seed 0 \
--gpu -1 \
--model ./models/MnihCNN_multi.py \
--train_ortho_db ./data/mass_buildings/lmdb/train_sat \
--train_label_db ./data/mass_buildings/lmdb/train_map \
--valid_ortho_db ./data/mass_buildings/lmdb/valid_sat \
--valid_label_db ./data/mass_buildings/lmdb/valid_map \
--dataset_size 1.0 \
> mnih_multi.log 2>&1 < /dev/null &