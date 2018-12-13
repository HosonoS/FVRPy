import numpy as np

#機械学習用
from sklearn.svm import SVC

#通信用
import socket

#描画用
import matplotlib.pyplot

#値切り捨て用
import math

import time

address = ('127.0.0.1',12345)
udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
udp.bind(address)


loopFlag = True
trainFlag = False
endFlag = False

count = 0

photoData = []

countMin = 0
countMax = 100
countEnd = 400

X = []
y = []

while loopFlag:
    rcv_byte = bytes()
    rcv_byte, addr = udp.recvfrom(4096)
    buffDataString = rcv_byte.decode(encoding='utf-8')
    buffData = buffDataString.split("+")
    buffData = buffData[1:]

    if(buffData[0] == "p"):

        if(count % 100 == 0):
            print("次のジェスチャまで待ちます")
            time.sleep(2)

        print("count")
        print(count)
        photoData = list(map(lambda x:int(x),buffData[1:-1]))

        if(count >= countMin  and count < countMax):
            if(not(endFlag)):
                X.append(photoData)
                y.append(math.floor(count/100))
                count += 1

                if(count % 100 == 0):
                    countMin += 100
                    countMax += 100

                if(count >= countEnd):
                    print("yo")
                    endFlag = True

        if(countEnd <= count):
            count += 1
            if(not(trainFlag)):
                clf = SVC(gamma='auto',C=1000)
                clf.fit(X,y)
            
            print(clf.predict([photoData]))


