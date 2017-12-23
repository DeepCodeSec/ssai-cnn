#!/usr/bin/env python
# -*- coding: utf-8 -*-

import chainer.functions as F
import chainer.links as L
from chainer import Chain


class MnihCNN_single(Chain):

    def __init__(self):
        super(MnihCNN_single, self).__init__(
            conv1=L.Convolution2D(3, 64, 16, stride=4, pad=0),
            conv2=L.Convolution2D(64, 112, 4, stride=1, pad=0),
            conv3=L.Convolution2D(112, 80, 3, stride=1, pad=0),
            fc4=L.Linear(5120, 4096),
            fc5=L.Linear(4096, 256),
        )
        self.train = True

    def __call__(self, x, t):
        h = F.relu(self.conv1(x))
        h = F.relu(self.conv2(h))
        h = F.relu(self.conv3(h))
        h = F.dropout(F.relu(self.fc4(h)), train=self.train)
        h = self.fc5(h)
        self.pred = F.reshape(h, (x.data.shape[0], 16, 16))

        if t is not None:
#            self.loss = F.sigmoid_cross_entropy(self.pred, t, normalize=False)
            self.loss = F.sigmoid_cross_entropy(self.pred, t)
            return self.loss
        else:
            self.pred = F.sigmoid(self.pred)
            return self.pred

model = MnihCNN_single()
