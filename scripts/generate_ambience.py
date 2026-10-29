"""Original carriage textures and a resolved dawn theme; standard library only."""
from array import array
from pathlib import Path
import math
import random
import sys
import wave

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / 'assets' / 'audio'


def strike(samples, start, duration, frequency, gain, decay=6):
    """A soft attack, decaying fundamental and two quieter partials."""
    first = round(start * RATE)
    count = min(round(duration * RATE), len(samples) - first)
    for index in range(count):
        t = index / RATE
        envelope = min(1, t * 160) * math.exp(-decay * t / duration)
        envelope *= min(1, (count - index - 1) / (RATE * .025))
        phase = math.tau * frequency * t
        tone = math.sin(phase) + .18 * math.sin(phase * 2.003) + .055 * math.sin(phase * 3.01)
        samples[first + index] += tone * envelope * gain


def rustle(samples, rng, start, duration, gain, smoothing=.5):
    first = round(start * RATE)
    count = min(round(duration * RATE), len(samples) - first)
    filtered = 0.0
    for index in range(count):
        noise = rng.uniform(-1, 1)
        filtered += smoothing * (noise - filtered)
        envelope = max(0, math.sin(math.pi * index / max(1, count - 1))) ** 1.5
        samples[first + index] += (noise - filtered) * envelope * gain


def carriage(identity):
    samples = [0.0] * (RATE * 12)
    rng = random.Random(1893 + identity)
    if identity == 0:
        # The exchange's clock, much quieter than any action or warning cue.
        for second in range(12):
            strike(samples, second + .25, .065, 1240 if second % 2 else 970, .12, 9)
    elif identity == 1:
        for start, hz in [(1.2, 1568), (4.6, 2093), (8.8, 1760)]:
            strike(samples, start, 2.2, hz, .052)
    elif identity == 2:
        # Slowly breathing wind and short, dry leaf movements.
        filtered = 0.0
        for index in range(len(samples)):
            t = index / RATE
            filtered += .035 * (rng.uniform(-1, 1) - filtered)
            samples[index] = filtered * (.13 + .08 * math.sin(math.tau * t / 12))
        for start in [.5, 2.7, 5.3, 7.8, 10.2]:
            rustle(samples, rng, start, .65, .028, .75)
    elif identity == 3:
        for start, hz in [(1.1, 2794), (4.8, 3520), (9.2, 2093)]:
            strike(samples, start, .42, hz, .10, 8)
            strike(samples, start + .055, .30, hz * 1.37, .034, 8)
    elif identity == 4:
        for start in [1.1, 4.2, 7.6, 10.3]:
            rustle(samples, rng, start, .75, .075, .12)
            rustle(samples, rng, start + .8, .12, .025, .35)
    elif identity == 5:
        for index in range(len(samples)):
            t = index / RATE
            breath = math.sin(math.pi * t / 12) ** 1.2
            samples[index] = breath * sum(
                .023 * (math.sin(math.tau * hz * t) + .09 * math.sin(math.tau * hz * 2 * t))
                for hz in [146.83, 174.61, 220]
            )
    else:
        for start, hz in [(1, 587.33), (4, 440), (7, 698.46), (10, 659.25)]:
            strike(samples, start, 1.9, hz, .045, 7)
    return samples


def morning():
    samples = [0.0] * (RATE * 24)
    # D major / G / A / D: the night theme's home key, with its third restored.
    chords = [(146.83, 185, 220), (196, 246.94, 293.66),
              (164.81, 220, 277.18), (146.83, 185, 220)]
    for index in range(len(samples)):
        t = index / RATE
        breath = math.sin(math.pi * (t % 6) / 6) ** .8
        samples[index] = breath * sum(
            .025 * (math.sin(math.tau * hz * t) + .09 * math.sin(math.tau * hz * 2 * t))
            for hz in chords[int(t / 6)]
        )
    for note, hz in enumerate([587.33, 739.99, 659.25, 880, 739.99, 659.25, 587.33, 587.33]):
        strike(samples, note * 3, 2.9, hz, .055)
    return samples


def write(name, samples):
    # A short edge taper keeps every loop click-free, including filtered noise.
    for index in range(min(round(RATE * .08), len(samples) // 2)):
        gain = index / (RATE * .08)
        samples[index] *= gain
        samples[-index - 1] *= gain
    peak = max(abs(value) for value in samples)
    rms = math.sqrt(sum(value * value for value in samples) / len(samples))
    if not .0001 < rms < .2 or peak >= .8:
        raise ValueError(f'{name}: unexpected audio level: peak={peak}, rms={rms}')
    pcm = array('h', (round(value * 32760) for value in samples))
    # WAV is little-endian even when the generator runs on a big-endian host.
    if sys.byteorder != 'little':
        pcm.byteswap()
    with wave.open(str(OUT / (name + '.wav')), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(pcm.tobytes())
    print(f'{name}: {len(samples) / RATE:.0f}s / peak {peak:.3f} / RMS {rms:.4f}')


def generate_all():
    OUT.mkdir(parents=True, exist_ok=True)
    for identity, name in enumerate(['exchange', 'observatory', 'garden', 'dining', 'archive', 'choir', 'last']):
        write('room_' + name, carriage(identity))
    write('morning', morning())


if __name__ == '__main__':
    generate_all()
