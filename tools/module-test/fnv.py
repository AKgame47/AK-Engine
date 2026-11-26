h = 1469598103934665603
for c in b'assets/hero.glb':
    h ^= c
    h = (h * 1099511628211) % (1 << 64)
print(h - (1 << 64) if h >= (1 << 63) else h)
