from pathlib import Path
import subprocess as sp
import json
import numpy as np
ROOT=Path(__file__).resolve().parent
src=ROOT/'AK-Engine-Forge-Ident.mp4'
info=json.loads(sp.check_output(['ffprobe','-v','error','-show_streams','-show_format','-of','json',str(src)]))
video=next(x for x in info['streams'] if x['codec_type']=='video')
audio=next(x for x in info['streams'] if x['codec_type']=='audio')
assert (video['width'],video['height'])==(1280,720) and video['r_frame_rate']=='24/1',video
assert video['codec_name']=='h264' and audio['codec_name']=='aac' and audio['channels']==2,audio
assert len(info['streams'])==2 and video['nb_frames']=='120' and abs(float(info['format']['duration'])-5)<.012,info
sound=np.frombuffer(sp.check_output(['ffmpeg','-v','error','-i',str(src),'-map','0:a','-f','f32le','-']),dtype='<f4').reshape(-1,2)
for name,at,length in [('start',0,.18),('first lock',27/24,.11),('copper impact',43/24,.15),('hold',4.1,.25)]:
 x=sound[round(at*48000):round((at+length)*48000)]
 peak=20*np.log10(max(np.max(np.abs(x)),1e-10));rms=20*np.log10(max(np.sqrt(np.mean(x*x)),1e-10))
 print(f'{name}: decoded audio peak {peak:.1f} dBFS, RMS {rms:.1f} dBFS')
assert np.max(np.abs(sound))<.98
frames=[(.79,'motion'),(43/24,'strike'),(3.7,'hold')]
for at,name in frames:
 d=sp.check_output(['ffmpeg','-v','error','-threads','2','-ss',f'{at:.6f}','-i',str(src),'-vf','scale=960:540','-frames:v','1','-c:v','png','-threads','2','-f','image2pipe','-'])
 (ROOT/f'QA-{name}.png').write_bytes(d)
print('Verified 120 frames / 1280x720 / 24 fps / 5.000s / H.264 + stereo AAC.')
