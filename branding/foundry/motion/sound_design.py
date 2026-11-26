"""Original AK Studio ident sound: synthesized foley, no external samples."""
from pathlib import Path
import numpy as np
import wave
from scipy import signal
SR=48000
LEN=5.0
rng=np.random.default_rng(28)
track=np.zeros((round(SR*LEN),2),dtype=np.float64)
def shaped(n, f1, f2):
 return signal.sosfilt(signal.butter(2,[f1,f2],btype='bandpass',fs=SR,output='sos'),rng.standard_normal(n))
def add(y, time, gain=1., pan=0.):
 off=round(time*SR)
 end=min(len(track),off+len(y))
 y=y[:end-off]
 gains=np.array([np.cos((pan+1)*np.pi/4),np.sin((pan+1)*np.pi/4)])*gain
 track[off:end]+=np.outer(y,gains)
def shift(at,length,pan,pitch):
 t=np.arange(round(SR*length))/SR
 u=t/length
 envelope=np.sin(np.pi*u)**2.4
 texture=.5*shaped(len(t),160,1900)+.22*shaped(len(t),2200,7800)
 chamber=.26*np.sin(2*np.pi*(75*t+(182*pitch)*t*t))*np.exp(-u*2.1)
 add((texture+chamber)*envelope,at,.79,pan)
def seat(at, pitch, pan, strength):
 t=np.arange(round(SR*.47))/SR
 i=(1-np.exp(-t/.001))*np.exp(-t/.023)
 attack=(.6*shaped(len(t),300,5000)+.19*shaped(len(t),5400,10000))*i
 hum=np.sin(2*np.pi*(83*pitch*t + 6.1*(1-np.exp(-t/.031))))*np.exp(-t/.044)
 ring=0.
 for k,(hz,w,damp) in enumerate([(346,.49,.044),(661,.23,.069),(1084,.12,.071),(2481,.04,.035)]):
  ring+=w*np.sin(2*np.pi*hz*pitch*t+.33*k)*(1-np.exp(-t/.0015))*np.exp(-t/damp)
 add((.63*attack+.39*hum+.60*ring),at,strength,pan)
 add(ring,at+.019,.13*strength,-pan*.66)
# Flights and synchronized locks. Blender frame 1 is t=0.
shift(.19,.90,-.53,.85)
shift(.39,1.03,.48,1.02)
shift(.77,.92,.23,1.56)
seat((28-1)/24,.84,-.54,.80)
seat((36-1)/24,1.05,.44,.88)
seat((44-1)/24,1.49,.17,.82)
# Forge strike: a dry split, a low thunder roll, and a narrow hot metallic tick.
at=(44-1)/24
t=np.arange(round(SR*.8))/SR
u=t/.8
crack=shaped(len(t),850,9000)*np.exp(-t/.024)*(1-np.exp(-t/.001))
thump=(np.sin(2*np.pi*(36*t+17*(1-np.exp(-t/.19))))*.48 + shaped(len(t),51,140)*.19)*(1-np.exp(-t/.011))*np.exp(-t/.22)
add(.38*crack+thump,at,.87,.025)
spark=shaped(len(t),4700,12200)*np.exp(-t/.073)*(1-np.exp(-t/.002))
add(spark,at+.025,.105,.54)
add(spark,at+.048,.081,-.44)
shift(1.50,.98,.03,.65)
seat((62-1)/24,.93,.04,.50)
# Warm settling motif built from struck partials. No music or sample sources.
for off,note,pan in [(2.49,146.832,-.23),(2.57,220.0,.27),(2.66,293.665,0.)]:
 t=np.arange(round(SR*2.25))/SR
 env=(1-np.exp(-t/.043))*np.exp(-t/.43)
 y=sum(a*np.sin(2*np.pi*note*p*t+ph)*np.exp(-t*decay)
  for a,p,ph,decay in [(1,1,0,0),(.21,2.005,.61,1.5),(.055,3.994,.13,2.7)])
 add(y*env,off,.082,pan)
 add(y*env,off+.042,.019,-pan)
t=np.arange(len(track))/SR
track*=np.clip(t/.05,0,1)[:,None]*np.clip((LEN-t)/.38,0,1)[:,None]
track=signal.sosfilt(signal.butter(2,35,btype='highpass',fs=SR,output='sos'),track,axis=0)
track=np.tanh(1.3*track)
track*=10**(-2.4/20)/max(np.max(np.abs(track)),1e-9)
out=Path(__file__).resolve().parent/'AK-Engine-Ident-Sound.wav'
with wave.open(str(out),'wb') as f:
 f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR);f.writeframes(np.around(track*32767).astype('<i2').tobytes())
