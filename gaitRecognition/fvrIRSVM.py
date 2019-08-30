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
import csv
import sys

address = ('127.0.0.1',12345)
udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
udp.bind(address)


loopFlag = True
trainFlag = False
trainEndFlag = False
waiting = False

count = 0

photoData = []

photoDataTest = []

trainDataLen = 10
gestureNum = 3
allDataLen = 100


X = []
y = []
testY = []

output = []

predicted = []

print("Start")

while loopFlag:

    rcv_byte = bytes()
    rcv_byte, addr = udp.recvfrom(4096)
    buffDataString = rcv_byte.decode(encoding='utf-8')
    buffData = buffDataString.split("+")
    buffData = buffData[1:]

    if(buffData[0] == "p"):

        #待ちのための処理
        if(count % trainDataLen == 0 and not(waiting)):
            print("次のジェスチャまで5秒待ちます")

            time.sleep(5)
            

            if(count == 1500):
                print("トレッドミルが動くまで待ちます")
                time.sleep(5)
                print("\007")
                print("pong")
            
            if(count <= trainDataLen * gestureNum):
                waiting = True

        else:
            #print("count")
            #print(count)
            photoData = list(map(lambda x:int(x),buffData[1:-1]))

            
            if(count <= trainDataLen * gestureNum):
                if(not(trainEndFlag)):
                    X.append(photoData)
                    y.append(math.floor(count/trainDataLen))
                    count += 1
    
                    #if(count % trainDataLen == 0):
                    #    countMin += trainDataLen
                    #    countMax += trainDataLen
    
                    if(count >= trainDataLen * gestureNum):
                        trainEndFlag = True
            
            else:
                photoDataTest.append(photoData)

            if(count % trainDataLen == 0 and count <= gestureNum * trainDataLen):
                waiting = False
    
        if(gestureNum * trainDataLen <= count):
            count += 1
            if(not(trainFlag)):
                clf = SVC(gamma='auto',C=100)
                clf.fit(X,y)
            
            predicted = clf.predict([photoData])
            print(predicted)
            testY.append(predicted)

            #print("5秒待ちます")
            #time.sleep(5)

    if count >= allDataLen:

        print("\007")
        print("pong")

        with open("test.csv","a") as f_handle:
            np.savetxt(f_handle,list(X),delimiter=',')
            np.savetxt(f_handle,list(y),delimiter=',')
            np.savetxt(f_handle,list(photoDataTest),delimiter=',')
            np.savetxt(f_handle,list(testY),delimiter=',')
            sys.exit()

