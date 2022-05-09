from cProfile import label
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.fft import fft, fftfreq
import soundfile as sf
import matplotlib.pyplot as plt

# read in data
a_df = pd.read_csv('accel.txt')
g_df = pd.read_csv('gyro.txt')

t_df = pd.read_csv('tilt.txt')

# graph accel tilt
time = [t - t_df['ts'][0] for t in t_df['ts']]
plt.plot(time, t_df['ta'])
plt.ylabel('Tilt from acceleration (deg)')
plt.xlabel('Time (s)')
plt.show()

# graph gyro tilt
plt.plot(time, t_df['tg'])
plt.ylabel('Tilt from gyroscope (deg)')
plt.xlabel('Time (s)')
plt.show()

# graph comp filter tilt
plt.plot(time, t_df['tc'])
plt.ylabel('Tilt from gyroscope (deg)')
plt.xlabel('Time (s)')
plt.show()



dims = ['x', 'y', 'z']

def noise(data: np.array):
    # average variance
    return np.var(data)

def bias(data: np.array):
    error = np.sum(0 - data)
    return error / len(data)

#accel
print('accel bias')
# 1 unit = -9.8m/s^2
ax_bias = bias(a_df['x'])
print('x: ', ax_bias)
ay_bias = bias(a_df['y'])
print('y: ', ay_bias)
z_adj = a_df['z'] + 1
az_bias = bias(z_adj)
print('z: ', az_bias)

n = np.mean([noise(a_df['x']), noise(a_df['y']), noise(a_df['z'])])
print("accel noise: ", n)

# gyro
print('gyro')
gx_bias = bias(g_df['x'])
print('x: ', gx_bias)
gy_bias = bias(g_df['y'])
print('y: ', gy_bias)
gz_bias = bias(g_df['z'])
print('z: ', gz_bias)

n = np.mean([noise(g_df['x']), noise(g_df['y']), noise(g_df['z'])])
print("accel noise: ", n)






