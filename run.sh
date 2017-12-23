#!/bin/bash

PYTHON_DIR=/usr/bin
PYTHON_BIN=python3.5

PYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.5m.so
PYTHON_INCLUDE=/usr/include/python3.5m
BOOST_INCLUDE=/usr/local/include
BOOST_NUMPY_INC=$BOOST_INCLUDE
BOOST_NUMPY_LIB=/usr/local/lib
OPENCV_DIR=/usr/local/share/OpenCV
URL_DATASETS=http://www.cs.toronto.edu/~vmnih/data/

#
#
NO=0
YES=1
#
CPU=-1
GPU=0
#
#
BUILD_UTILS=$NO
DOWNLOAD_DATASETS=$NO
CREATE_DATASET=$NO
TRAIN_DATASET=$NO
SSAI_HOME=$(pwd)
DATASET="buildings"
MODEL="single"

PYTHON=$PYTHON_DIR/$PYTHON_BIN

usage() {
	echo "Usage: $0 -d DATASET [-m MODEL] [-w] [-b] [-c] [-t]" 1>&2;
	echo "    -d;	Specifies the dataset to train: multi, roads, buildings, roads_mini"
	echo "    -w;	Downloads the datasets from $URL_DATASETS."
	echo "    -b;	Builds the ssai-cnn utils."
	echo "    -c;	Creates the specific dataset."
	echo "    -t;	Starts the training on the given dataset."
	echo "    -m;	Specifies the model to use: single, multi."
	exit 1;
}

while getopts ":bwctm:d:" o; do
    case "${o}" in
        w)
            DOWNLOAD_DATASETS=$YES
            ;;
        b)
            BUILD_UTILS=$YES
            ;;
        c)
            CREATE_DATASET=$YES
            ;;
        d)
            DATASET=${OPTARG}
			((DATASET="multi") || (DATASET="roads") || (DATASET="buildings") || (DATASET="roads_mini")) || usage
            ;;
        t)
            TRAIN_DATASET=$YES
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${DATASET}" ]; then
    usage
fi

export PYTHONPATH=.:$PYTHONPATH

if [ $BUILD_UTILS == $YES ]; then
	echo "[=] Building ssai-cnn utils..."
	cd $SSAI_HOME/utils
	cmake \
		-DPYTHON_LIBRARY=$PYTHON_LIBRARY \
		-DPYTHON_INCLUDE_DIR=$PYTHON_INCLUDE \
		-DBoost_INCLUDE_DIR=$BOOST_INCLUDE \
		-DBoost_NumPy_INCLUDE_DIR=/usr/local/include \
		-DBoost_NumPy_LIBRARY_DIR=$BOOST_NUMPY_LIB \
		-DOpenCV_DIR=$OPENCV_DIR \
		-Wno-dev \
		.
	make

	echo "[=] make returned exit code '$?'."
	if [ $? <> 0 ]; then
		exit $?
	fi
fi

if [ $DOWNLOAD_DATASETS == $YES ]; then
	echo "[=] Downloading data..."
	wget \
		--recursive \
		--page-requisites \
		--html-extension \
		--no-parent \
		--reject *.zip \
		--reject *.html \
		--reject *.txt \
		$URL_DATASETS
	mv www.cs.toronto.edu/~vmnih/data $SSAI_HOME

	cd $SSAI_HOME/data
	wget -O multi_test_map.tar.gz https://www.dropbox.com/s/yk6d4garyz3nm19/multi_test_map.tar.gz?dl=0
	tar zxvf multi_test_map.tar.gz
	rm -rf multi_test_map.tar.gz
fi

if [ $CREATE_DATASET == $YES ]; then
	echo "[=] Creating '$DATASET' dataset..."
	$PYTHON $SSAI_HOME/scripts/create_dataset.py --dataset $DATASET
	echo "[=] create_dataset.py returned exit code '$?'."

	echo "[=] Testing '$DATASET' dataset..."
	$PYTHON $SSAI_HOME/tests/test_dataset.py \
		--ortho_db data/mass_$DATASET/lmdb/train_sat \
		--label_db data/mass_$DATASET/lmdb/train_map \
		--out_dir data/mass_$DATASET/patch_test
	echo "[=] test_dataset.py returned exit code '$?'."

	echo "[=] Testing '$DATASET' transforms..."
	$PYTHON $SSAI_HOME/tests/test_transform.py \
		--ortho_db data/mass_$DATASET/lmdb/train_sat \
		--label_db data/mass_$DATASET/lmdb/train_map \
		--out_dir data/mass_$DATASET/trans_test
	echo "[=] test_transform.py returned exit code '$?'."
fi

if [ $TRAIN_DATASET == $YES ]; then
	echo "[=] Training..."
	CHAINER_TYPE_CHECK=0 CHAINER_SEED=$1 \
	nohup $PYTHON ./scripts/train.py \
		--seed 0 \
		--gpu $CPU \
		--model ./models/MnihCNN_$MODEL.py \
		--train_ortho_db ./data/mass_$DATASET/lmdb/train_sat \
		--train_label_db ./data/mass_$DATASET/lmdb/train_map \
		--valid_ortho_db ./data/mass_$DATASET/lmdb/valid_sat \
		--valid_label_db ./data/mass_$DATASET/lmdb/valid_map \
		--dataset_size 1.0 \
		> mnih_multi.log 2>&1 < /dev/null &
	echo "[=] train.py returned exit code '$?'."
fi

echo "[!] Completed."
exit 0
