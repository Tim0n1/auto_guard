import matplotlib.pyplot as plt
import numpy as np
from matplotlib.animation import FFMpegWriter
plt.rcParams["animation.ffmpeg_path"] = "C:\\Users\\timon\\Documents\\ffmpeg-master-latest-win64-gpl\\bin\\ffmpeg.exe"

fig = plt.figure()
l, = plt.plot([], [], 'k--')
l2, = plt.plot([],[],'m--')
l3, = plt.plot([], [], )
plt.ylim(-5,10)
plt.xlim(-5,5)

writer = FFMpegWriter(fps=60)

X = np.linspace(-5,5, 400)
x_values = []
y_values = []
y_der = []
def f(x):
    return np.sin(x)

def grad_f(x):
    return np.cos(x)


with writer.saving(fig, 'skica.mp4', 100):
    tangent_length = 3
    for i in X:
        x_values.append(i)
        y_values.append(f(i))
        y_der.append(grad_f(i))

        l.set_data(x_values, y_values)
        #l2.set_data(x_values, y_der)
    for i in X:
        interval = (np.sqrt(tangent_length/4))/np.sqrt(grad_f(i)**2 + 1)
        l3.set_data(np.linspace(i-interval,i+interval, num=30), grad_f(i)*(np.linspace(i-interval,i+interval,num=30) - i) + f(i))
        writer.grab_frame()

