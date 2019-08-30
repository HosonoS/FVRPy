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
endFlag = False
waiting = False

count = 0

photoData = []
accelData = []
#
photoDataTrain = []
accelDataTrain = []
photoDataTest = []
accelDataTest = []

countMin = 0
countMax = 100
countEnd = 300

X = []
y = []

output = []

predicted = []

print("Start")
print("\007")

while loopFlag:

    rcv_byte = bytes()
    rcv_byte, addr = udp.recvfrom(4096)
    buffDataString = rcv_byte.decode(encoding='utf-8')
    buffData = buffDataString.split("+")
    buffData = buffData[1:]

    if(buffData[0] == "p"):

        if(count % 100 == 0 and not(waiting)):
            print("次のジェスチャまで5秒待ちます")
            time.sleep(5)
            waiting = True

        else:
            photoData = list(map(lambda x:float(x),buffData[1:-1]))
            print(photoData)

            if(count >= countMin  and count < countMax):
                if(not(endFlag)):
                    photoDataTrain.append(photoData)
                    y.append(math.floor(count/100))
                    count += 1
    
                    if(count % 100 == 0):
                        countMin += 100
                        countMax += 100
    
                    if(count >= countEnd):
                        endFlag = True

            else:
                photoDataTest.append(photoData)

            if(count % 100 == 0):
                waiting = False
    
           #time.sleep(5)

    if(buffData[0] == "a"):
        print(buffData[1:])
        accelData = list(map(lambda x:float(x),buffData[1:]))
        
        if not(trainFlag):
            accelDataTrain.append(accelData)
        else:
            accelDataTest.append(accelData)

    if(countEnd <= count):
        count += 1
        if(not(trainFlag)):
            clf = SVC(gamma='auto',C=100)

            while(len(accelDataTrain) > len(photoDataTrain)):
                accelDataTrain.pop(-1)

            print(len(photoDataTrain))
            print(len(accelDataTrain))
            print(count)

            X = np.concatenate((photoDataTrain,accelDataTrain),axis=1)
            clf.fit(X,y)
            trainFlag = True

        predictInput= []
        predictInput.extend(photoData[:])
        predictInput.extend(accelData[:])
        
        #print(predictInput)
        print(clf.predict([predictInput]))
        #print("5秒待ちます")

    if count >= 1000:
        print("\007")
        with open("outputData.csv","a") as f_handle:
            np.savetxt(f_handle,list(X),delimiter=',')
            np.savetxt(f_handle,list(y),delimiter=',')
            np.savetxt(f_handle,list(photoDataTest),delimiter=',')

            sys.exit()
