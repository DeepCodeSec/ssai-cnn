PYTHON_DIR=/usr/bin
cmake \
-DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.5m.so \
-DPYTHON_INCLUDE_DIR=/usr/include/python3.5m \
-DPYTHON_INCLUDE_DIR2=/usr/include \
-DBoost_INCLUDE_DIR=/usr/local/include \
-DBoost_NumPy_INCLUDE_DIR=/usr/local/include \
-DBoost_NumPy_LIBRARY_DIR=/usr/local/lib \
-DOpenCV_DIR=/usr/local/share/OpenCV \
-Wno-dev \
. && make
