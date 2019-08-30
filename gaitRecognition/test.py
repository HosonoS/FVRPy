from mutagen.mp3 import MP3 as mp3
import pygame

filename = 'clap.mp3'
pygame.mixer.init()
pygame.mixer.music.load(filename)
mp3_length = mp3(filename).info.length #音源の長さ取得
#pygame.mixer.music.play(1)
#time.sleep(mp3_length + 0.25) #再生開始後、音源の長さだけ待つ(0.25待つのは誤差解消)
#pygame.mixer.music.stop() #音源の長さ待ったら再生停止
