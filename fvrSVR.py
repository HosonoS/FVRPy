from sklearn.svm import SVR
import numpy as np

import socket
from sklearn import svm

import matplotlib.pyplot as plt

import time

import serial

#ser = serial.Serial('/dev/cu.usbmodem141121',115200)
#ser = serial.Serial('/dev/cu.usbmodem143141',115200)
ser = serial.Serial('/dev/cu.usbmodem141141',115200)

photoData = []
count = 0
timeCount = 0
loopFlag = True

address = ('127.0.0.1',12345)

X = []
y = []
checkData = []

plotCount = 0
plotX = []
plotY = []
plotPredictedY = []
plotPredictedYAll = []

udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
udp.bind(address)


trained = False

#svm = SVR(gamma=(2**0-15),C=1000)

svr_rbf = SVR(kernel='rbf',C=1e3,gamma=0.1)


while loopFlag:
    rcv_byte = bytes() #バイトデータ受信用変数
    rcv_byte, addr = udp.recvfrom(4096) #括弧内は最大バイト数設定
    buffDataString = rcv_byte.decode(encoding='utf-8')
    buffData = buffDataString.split("+")
    buffData = buffData[1:]

  #  print(ser.readline().decode('utf-8'))

    if(buffData[0] == 'p'):
        photoData = list(map(lambda x: int(x),buffData[1:-1]))
        X.append(np.array(photoData))
        y.append(int(ser.readline().decode('utf-8')))
        count += 1
 #       print("Hey")
        print("カウント" + str(count))
        print("圧力センサーの値" + str(y[len(y)-1]))

    if(count >= 1000):
        if not(trained):
            svr_rbf.fit(X,y)
        print("測定値:" + str(ser.readline().decode('utf-8')))
        print("予測値:" + str(svr_rbf.predict([photoData])))

        plotX.append(plotCount)
        plotY.append(int(ser.readline().decode('utf-8')))
        plotPredictedY.append(list(svr_rbf.predict([photoData]))[0])

        plotCount += 1

    if plotCount >= 100:

        print(plotY)
        print(list(plotPredictedY))
        print("Hey")

        plt.plot(plotX,plotY)
        plt.plot(plotX,plotPredictedY)
        plt.show()

