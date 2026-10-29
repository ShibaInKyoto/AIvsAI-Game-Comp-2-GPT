"""Original procedural score and effects. Standard library only; no downloaded audio."""
from array import array
from pathlib import Path
import math
import random
import wave
from generate_ambience import generate_all

OUT = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
OUT.mkdir(parents=True, exist_ok=True)
RATE = 22050

def write(name, samples):
    with wave.open(str(OUT / (name + '.wav')), 'wb') as f:
        f.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        f.writeframes(array('h', (round(max(-1, min(1, x)) * 32760) for x in samples)).tobytes())

def tone(name, frequencies, duration, volume=0.4):
    def sample(i):
        t = i / RATE
        attack = min(1, t / 0.008)
        return sum(math.sin(2 * math.pi * hz * t) for hz in frequencies) / len(frequencies) * math.exp(-t * 5 / duration) * attack * volume
    write(name, (sample(i) for i in range(int(RATE * duration))))

tone('take', [523.25, 783.99, 1046.5], 0.55, 0.35)
tone('bank', [261.63, 329.63, 392, 523.25], 1.5, 0.4)
tone('fold', [146.83, 220, 293.66, 440], 2.2, 0.3)
tone('caught', [98, 103.83, 146.83], 1.6, 0.45)
tone('chime', [220, 440.7, 661.8], 2.0, 0.25)
tone('step', [68, 107], 0.14, 0.15)
tone('click', [660, 880], 0.2, 0.2)

# 48-second seamless original ambient piece: D minor / Bb / F / A sus.
chords = [(146.83, 174.61, 220), (116.54, 146.83, 174.61), (130.81, 174.61, 220), (110, 146.83, 164.81)]
random.seed(36)
phases = [random.random() * math.tau for _ in range(3)]
length = 48
samples = array('h')
for i in range(RATE * length):
    t = i / RATE
    chord = chords[int(t / 12) % 4]
    local = t % 12
    envelope = math.sin(math.pi * local / 12) ** 0.7
    value = 0.0
    for j, hz in enumerate(chord):
        value += (math.sin(math.tau * hz * t + phases[j]) + 0.25 * math.sin(math.tau * hz * 2.002 * t)) * envelope * 0.035
    # Gently struck upper notes, every three seconds.
    note = [293.66, 440, 349.23, 261.63, 349.23, 293.66, 220, 329.63][int(t / 3) % 8]
    nt = t % 3
    value += math.sin(math.tau * note * nt) * math.exp(-nt * 2.5) * min(1, nt * 70) * 0.045
    samples.append(round(value * 32760))
with wave.open(str(OUT / 'night.wav'), 'wb') as f:
    f.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
    f.writeframes(samples.tobytes())
# Low train bed: deterministic, filtered noise and repeating rail-joint rhythm.
noise = 0.0
samples = array('h')
for i in range(RATE * 8):
    t = i / RATE
    noise = noise * 0.965 + random.uniform(-1, 1) * 0.035
    pulse = math.exp(-(t % 0.4) * 65)
    value = noise * 0.3 + math.sin(math.tau * 43 * t) * 0.025 + pulse * math.sin(math.tau * 82 * t) * 0.055
    edge = min(1, t * 10, (8 - t) * 10)
    samples.append(round(value * edge * 32760))
with wave.open(str(OUT / 'train.wav'), 'wb') as f:
    f.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
    f.writeframes(samples.tobytes())
print('Generated original score, train ambience and seven effects.')

generate_all()
