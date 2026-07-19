#!/usr/bin/env python3
"""Generate the project's original procedural BGM and SFX masters.

The generator intentionally uses only Python's standard library so the audio can
be rebuilt without a DAW or a network service.  It writes 44.1 kHz stereo WAV
 masters. Runtime AAC/M4A files are produced from these masters with
 ``afconvert`` on macOS (see ``--encode-runtime``).
"""

from __future__ import annotations

import argparse
import math
import random
import shutil
import subprocess
import tempfile
import wave
from array import array
from functools import lru_cache
from pathlib import Path
from typing import Callable


SAMPLE_RATE = 44_100
TAU = math.tau
StereoSample = tuple[float, float]
Sampler = Callable[[float], StereoSample]


def _osc(freq: float, time: float, phase: float = 0.0) -> float:
    return math.sin(TAU * freq * time + phase)


def _triangle(freq: float, time: float) -> float:
    return 2.0 * abs(2.0 * ((time * freq) % 1.0) - 1.0) - 1.0


def _pulse(freq: float, time: float, width: float = 0.5) -> float:
    return 1.0 if (time * freq) % 1.0 < width else -1.0


def _envelope(
    time: float,
    start: float,
    length: float,
    attack: float = 0.04,
    release: float = 0.5,
) -> float:
    local = time - start
    if local < 0.0 or local >= length:
        return 0.0
    if local < attack:
        return local / max(attack, 0.001)
    tail = length - local
    if tail < release:
        return tail / max(release, 0.001)
    return 1.0


def _note(freq: float, time: float, start: float, length: float) -> float:
    env = _envelope(time, start, length)
    if env == 0.0:
        return 0.0
    local = time - start
    body = (
        _osc(freq, local)
        + 0.36 * _osc(freq * 2.0, local, 0.1)
        + 0.14 * _osc(freq * 3.0, local, 0.3)
    )
    return body * env * math.exp(-local * 0.7)


def _bell(freq: float, time: float, start: float, length: float = 3.2) -> float:
    env = _envelope(time, start, length, attack=0.008, release=0.8)
    if env == 0.0:
        return 0.0
    local = time - start
    return env * math.exp(-local * 0.58) * (
        _osc(freq, local)
        + 0.52 * _osc(freq * 2.01, local, 0.3)
        + 0.24 * _osc(freq * 3.97, local, 0.7)
    )


def _pad(freqs: tuple[float, ...], time: float, drift: float = 0.0) -> float:
    total = 0.0
    for index, freq in enumerate(freqs):
        phase = index * 0.83
        total += _osc(freq, time, phase)
        total += 0.22 * _osc(freq * 2.0, time, phase + 0.5)
        total += 0.08 * _osc(freq * 0.5, time, phase + drift)
    return total / max(len(freqs), 1)


@lru_cache(maxsize=None)
def _air_components(seed: int) -> tuple[tuple[float, float, float], ...]:
    rng = random.Random(seed)
    return tuple(
        (
            rng.uniform(0.17, 7.5) * harmonic,
            rng.uniform(0.0, TAU),
            1.0 / (harmonic + 2.0),
        )
        for harmonic in range(1, 15)
    )


def _air(time: float, seed: int) -> float:
    value = 0.0
    for freq, phase, weight in _air_components(seed):
        value += _osc(freq, time, phase) * weight
    return value * 0.12


def _soft_clip(value: float) -> float:
    return math.tanh(value * 1.12) * 0.82


def _write_wav(path: Path, duration: float, sampler: Sampler) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    frame_count = int(duration * SAMPLE_RATE)
    chunk_size = 4096
    with wave.open(str(path), "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        for first in range(0, frame_count, chunk_size):
            pcm = array("h")
            for frame in range(first, min(first + chunk_size, frame_count)):
                left, right = sampler(frame / SAMPLE_RATE)
                pcm.append(int(max(-1.0, min(1.0, _soft_clip(left))) * 32767))
                pcm.append(int(max(-1.0, min(1.0, _soft_clip(right))) * 32767))
            output.writeframes(pcm.tobytes())


def _events(time: float, notes: list[tuple[float, float, float]]) -> float:
    return sum(_note(freq, time, start, length) for start, freq, length in notes)


def _loop_notes(
    pitches: tuple[float, ...],
    *,
    interval: float,
    offset: float,
    length: float,
    duration: float,
) -> list[tuple[float, float, float]]:
    result: list[tuple[float, float, float]] = []
    cursor = offset
    index = 0
    while cursor < duration:
        result.append((cursor, pitches[index % len(pitches)], length))
        cursor += interval
        index += 1
    return result


def _bgm_samplers(duration: float) -> dict[str, Sampler]:
    night_notes = _loop_notes(
        (220.0, 261.63, 246.94, 196.0),
        interval=8.0,
        offset=3.0,
        length=4.5,
        duration=duration,
    )
    xingyao_notes = _loop_notes(
        (440.0, 554.37, 659.25, 554.37, 493.88, 659.25, 739.99, 659.25),
        interval=2.0,
        offset=0.5,
        length=2.2,
        duration=duration,
    )
    sumi_notes = _loop_notes(
        (196.0, 246.94, 293.66, 261.63, 220.0, 261.63, 329.63, 293.66),
        interval=4.0,
        offset=1.0,
        length=4.8,
        duration=duration,
    )
    lincheng_notes = _loop_notes(
        (523.25, 659.25, 783.99, 659.25, 587.33, 698.46, 880.0, 698.46),
        interval=1.5,
        offset=0.25,
        length=2.0,
        duration=duration,
    )
    rescue_notes = _loop_notes(
        (146.83, 174.61, 196.0, 220.0),
        interval=2.0,
        offset=0.0,
        length=2.6,
        duration=duration,
    )
    core_notes = _loop_notes(
        (146.83, 155.56, 220.0, 207.65, 146.83, 174.61),
        interval=3.0,
        offset=1.0,
        length=2.8,
        duration=duration,
    )
    shutdown_notes = _loop_notes(
        (293.66, 369.99, 440.0, 587.33, 440.0, 369.99),
        interval=1.0,
        offset=0.0,
        length=1.3,
        duration=duration,
    )
    aftermath_notes = _loop_notes(
        (220.0, 196.0, 164.81, 146.83),
        interval=6.0,
        offset=1.5,
        length=5.2,
        duration=duration,
    )

    def night(time: float) -> StereoSample:
        pad = _pad((55.0, 65.41, 82.41), time, 0.2) * 0.19
        piano = _events(time, night_notes) * 0.12
        air = _air(time, 11)
        distant = _osc(0.125, time) * _osc(110.0, time) * 0.035
        return pad + piano + air + distant, pad + piano * 0.9 + air * 0.8 - distant

    def xingyao(time: float) -> StereoSample:
        pad = _pad((110.0, 138.59, 164.81), time, 0.7) * 0.11
        bells = sum(_bell(freq, time, start, 2.6) for start, freq, _ in xingyao_notes) * 0.12
        digital = _pulse(3.0, time, 0.08) * _osc(880.0, time) * 0.012
        return pad + bells + digital, pad * 0.92 + bells * 0.84 - digital

    def sumi(time: float) -> StereoSample:
        pad = _pad((65.41, 98.0, 123.47), time, 0.4) * 0.17
        piano = _events(time, sumi_notes) * 0.15
        cello = _osc(98.0, time) * (0.5 + 0.5 * _osc(0.0625, time)) * 0.055
        return pad + piano + cello, pad * 0.96 + piano * 0.9 + cello * 1.08

    def lincheng(time: float) -> StereoSample:
        pad = _pad((130.81, 164.81, 196.0), time, 0.1) * 0.10
        bells = sum(_bell(freq, time, start, 2.2) for start, freq, _ in lincheng_notes) * 0.105
        pluck = _triangle(2.0, time) * _osc(261.63, time) * 0.018
        return pad + bells + pluck, pad * 0.9 + bells * 0.86 - pluck

    def betrayal(time: float) -> StereoSample:
        beat = time % 4.0
        kick_env = math.exp(-((beat % 1.0) * 9.0))
        kick = _osc(52.0 - 18.0 * min(beat % 1.0, 0.2), time) * kick_env * 0.22
        metal = _triangle(7.0, time) * _osc(934.0, time) * (0.025 if beat > 2.6 else 0.008)
        drone = _pad((46.25, 65.41, 69.30), time, 1.1) * 0.22
        irregular = _pulse(0.375, time, 0.09) * _osc(116.54, time) * 0.06
        return drone + kick + metal + irregular, drone * 0.94 + kick - metal - irregular * 0.7

    def audit(time: float) -> StereoSample:
        progress = 0.35 + 0.65 * min(time / duration, 1.0)
        cold = _pad((73.42, 77.78, 110.0), time, 0.6) * 0.16
        warm = _pad((73.42, 92.50, 110.0, 138.59), time, 0.2) * 0.14 * progress
        motif = 0.0
        for base in range(0, int(duration), 8):
            motif += _bell(293.66, time, base + 0.5, 3.0) * 0.10
            motif += _bell(311.13, time, base + 2.0, 3.0) * 0.08
            motif += _bell(440.0, time, base + 3.5, 4.0) * 0.09
        return cold + warm + motif, cold * 0.92 + warm * 1.06 + motif * 0.86

    def rescue(time: float) -> StereoSample:
        beat = time % 2.0
        pulse = _osc(73.42, time) * math.exp(-(beat % 0.5) * 7.0) * 0.11
        notes = _events(time, rescue_notes) * 0.08
        pad = _pad((73.42, 98.0, 116.54), time, 0.4) * 0.14
        ticks = _pulse(4.0, time, 0.06) * _osc(1600.0, time) * 0.013
        return pad + pulse + notes + ticks, pad * 0.95 + pulse + notes * 0.87 - ticks

    def control_core(time: float) -> StereoSample:
        drone = _pad((49.0, 61.74, 73.42), time, 0.45) * 0.18
        motif = _events(time, core_notes) * 0.10
        clock = _pulse(2.0, time, 0.045) * _osc(1240.0, time) * 0.014
        scan = _osc(0.125, time) * _osc(92.50, time) * 0.035
        return drone + motif + clock + scan, drone * 0.94 + motif * 0.86 - clock - scan * 0.7

    def synchronized_shutdown(time: float) -> StereoSample:
        beat = time % 1.0
        pulse = _osc(65.41, time) * math.exp(-beat * 8.0) * 0.13
        sequence = _events(time, shutdown_notes) * 0.075
        pad = _pad((65.41, 82.41, 98.0), time, 0.35) * 0.13
        relay = _pulse(4.0, time, 0.035) * _osc(1760.0, time) * 0.012
        return pad + pulse + sequence + relay, pad * 0.95 + pulse + sequence * 0.84 - relay

    def four_seat_aftermath(time: float) -> StereoSample:
        hollow = _pad((55.0, 65.41, 82.41), time, 0.9) * 0.16
        piano = _events(time, aftermath_notes) * 0.14
        four_count = sum(
            _bell(329.63, time, base + step * 0.55, 2.1) * 0.045
            for base in range(0, int(duration), 16)
            for step in range(4)
        )
        air = _air(time, 117) * 0.9
        return hollow + piano + four_count + air, hollow * 0.92 + piano * 0.88 + four_count * 1.05 + air * 0.75

    return {
        "night_facility": night,
        "bond_xingyao": xingyao,
        "bond_sumi": sumi,
        "bond_lincheng": lincheng,
        "betrayal_hunt": betrayal,
        "audit_revelation": audit,
        "rescue_action": rescue,
        "control_core_protocol": control_core,
        "synchronized_shutdown": synchronized_shutdown,
        "four_seat_aftermath": four_seat_aftermath,
    }


def _sfx_samplers() -> dict[str, tuple[float, Sampler]]:
    def stereo(mono: Callable[[float], float], pan: float = 0.0) -> Sampler:
        return lambda time: (mono(time) * (1.0 - max(0.0, pan)), mono(time) * (1.0 + min(0.0, pan)))

    def decay_tone(freq: float, decay: float, *, metallic: bool = False) -> Callable[[float], float]:
        def sample(time: float) -> float:
            body = _osc(freq, time)
            if metallic:
                body += 0.55 * _osc(freq * 1.43, time) + 0.25 * _osc(freq * 2.17, time)
            return body * math.exp(-time * decay) * 0.42

        return sample

    def motor(time: float) -> float:
        ramp = min(time / 0.35, 1.0) * min((4.8 - time) / 0.5, 1.0)
        return ramp * (0.16 * _triangle(23.0, time) + 0.10 * _osc(91.0, time) + _air(time, 91))

    def impact(time: float) -> float:
        return math.exp(-time * 4.2) * (
            0.42 * _osc(43.0, time) + 0.22 * _triangle(117.0, time) + _air(time, 22)
        )

    def splash(time: float) -> float:
        env = math.exp(-time * 2.8)
        return env * (_air(time * 5.0, 31) + 0.16 * _osc(970.0 + 260.0 * time, time))

    def shower(time: float) -> float:
        ramp = min(time / 0.2, 1.0) * min((5.0 - time) / 0.35, 1.0)
        return ramp * (_air(time * 7.0, 41) + 0.035 * _triangle(137.0, time))

    def gas(time: float) -> float:
        ramp = min(time / 0.25, 1.0) * min((6.0 - time) / 0.8, 1.0)
        return ramp * (_air(time * 9.0, 51) + 0.055 * _osc(63.0, time))

    def pneumatic_nailer(time: float) -> float:
        charge = _air(time * 12.0, 121) * min(time / 0.06, 1.0) * math.exp(-time * 5.0)
        strike_time = max(time - 0.16, 0.0)
        strike = impact(strike_time) * (1.0 if time >= 0.16 else 0.0)
        metal = decay_tone(1480.0, 7.5, metallic=True)(strike_time) if time >= 0.16 else 0.0
        return charge * 1.4 + strike * 1.2 + metal * 0.55

    def electrical_arc(time: float) -> float:
        crackle = _pulse(31.0 + 7.0 * _osc(1.7, time), time, 0.13)
        high = _osc(1380.0 + 520.0 * _osc(13.0, time), time)
        surge = min(time / 0.04, 1.0) * min((2.1 - time) / 0.35, 1.0)
        return surge * (0.13 * crackle * high + 0.10 * _triangle(93.0, time) + _air(time * 13.0, 131))

    def pressure_bypass(time: float) -> float:
        valve = decay_tone(280.0, 4.5, metallic=True)(time) * 0.75
        flow = gas(time) * 0.82
        latch_time = max(time - 3.65, 0.0)
        latch = impact(latch_time) * 0.55 if time >= 3.65 else 0.0
        return valve + flow + latch

    def evidence_glass_break(time: float) -> float:
        base = impact(time) * 0.9
        shards = sum(
            decay_tone(freq, 6.0 + index, metallic=True)(max(time - offset, 0.0))
            * (0.34 / (index + 1))
            * (1.0 if time >= offset else 0.0)
            for index, (offset, freq) in enumerate(
                ((0.03, 1260.0), (0.11, 1780.0), (0.19, 2320.0), (0.31, 1540.0))
            )
        )
        scatter = _air(time * 18.0, 141) * math.exp(-time * 3.1)
        return base + shards + scatter

    def sync_lock_pulse(time: float) -> float:
        tones = (
            _bell(392.0, time, 0.0, 1.2)
            + _bell(523.25, time, 0.34, 1.2)
            + _bell(783.99, time, 0.68, 1.5)
        ) * 0.23
        lock_time = max(time - 1.04, 0.0)
        lock = impact(lock_time) * 0.55 if time >= 1.04 else 0.0
        return tones + lock

    def ambience(seed: int, hum: float) -> Sampler:
        return lambda time: (
            _air(time, seed) + 0.035 * _osc(hum, time),
            _air(time, seed + 1) + 0.035 * _osc(hum * 1.005, time),
        )

    return {
        "route_jump": (0.9, stereo(lambda t: _bell(660.0, t, 0.0, 0.9) * 0.42)),
        "administrator_channel_off": (1.2, stereo(decay_tone(420.0, 3.5))),
        "surveillance_servo": (1.5, stereo(lambda t: motor(t * 3.2) * 0.55)),
        "amb_assembly_pa": (12.0, ambience(60, 50.0)),
        "amb_infirmary_equipment": (12.0, ambience(64, 60.0)),
        "amb_storage_refrigeration": (12.0, ambience(68, 44.0)),
        "footsteps_concrete": (2.2, stereo(lambda t: sum(impact(t - s) if t >= s else 0.0 for s in (0.0, 0.55, 1.1, 1.65)) * 0.58)),
        "rope_tension": (2.0, stereo(lambda t: _triangle(78.0 + 22.0 * t, t) * math.exp(-t * 0.9) * 0.13)),
        "medical_monitor": (4.0, stereo(lambda t: decay_tone(880.0, 9.0)(t % 1.0) if t % 1.0 < 0.25 else 0.0)),
        "uv_lamp": (1.3, stereo(lambda t: decay_tone(1220.0, 3.8)(t) + 0.05 * _osc(120.0, t))),
        "measuring_tape": (1.8, stereo(lambda t: _triangle(310.0 + 90.0 * t, t) * math.exp(-t * 1.7) * 0.14)),
        "archive_page": (1.4, stereo(lambda t: _air(t * 11.0, 73) * math.exp(-t * 2.4))),
        "microfilm_scanner": (2.4, stereo(lambda t: motor(t * 1.8) * 0.36 + decay_tone(980.0, 4.0)(t) * 0.18)),
        "archive_shelf_motor": (5.0, stereo(motor)),
        "archive_shelf_impact": (2.4, stereo(impact)),
        "acid_splash": (2.2, stereo(splash, -0.2)),
        "emergency_shower": (5.2, stereo(shower, 0.15)),
        "gas_release": (6.2, stereo(gas)),
        "archive_seal": (6.0, stereo(lambda t: motor(t * 0.82) * 0.8 + (impact(t - 4.6) if t >= 4.6 else 0.0))),
        "checksum_verified": (1.8, stereo(lambda t: _bell(523.25, t, 0.0, 1.8) * 0.28 + _bell(783.99, t, 0.28, 1.4) * 0.22)),
        "pneumatic_nailer": (1.3, stereo(pneumatic_nailer, -0.12)),
        "electrical_arc": (2.2, stereo(electrical_arc, 0.15)),
        "pressure_bypass": (4.8, stereo(pressure_bypass)),
        "evidence_glass_break": (1.8, stereo(evidence_glass_break, -0.08)),
        "sync_lock_pulse": (2.4, stereo(sync_lock_pulse)),
    }


def _encode_runtime(wav_path: Path, output_path: Path) -> None:
    afconvert = shutil.which("afconvert")
    if afconvert is None:
        raise RuntimeError("afconvert is required for --encode-runtime")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            afconvert,
            str(wav_path),
            str(output_path),
            "-f",
            "m4af",
            "-d",
            "aac",
            "-b",
            "160000",
        ],
        check=True,
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-root", type=Path, default=Path("assets/audio"))
    parser.add_argument("--bgm-seconds", type=float, default=64.0)
    parser.add_argument("--encode-runtime", action="store_true")
    parser.add_argument(
        "--only",
        action="append",
        default=[],
        help="Generate only these comma-separated cue ids.",
    )
    args = parser.parse_args()
    selected = {
        name.strip()
        for group in args.only
        for name in group.split(",")
        if name.strip()
    }

    with tempfile.TemporaryDirectory(prefix="zero-hour-audio-") as temp_dir:
        temp_root = Path(temp_dir)
        for name, sampler in _bgm_samplers(args.bgm_seconds).items():
            if selected and name not in selected:
                continue
            wav_path = temp_root / f"{name}.wav" if args.encode_runtime else args.output_root / "bgm" / f"{name}.wav"
            _write_wav(wav_path, args.bgm_seconds, sampler)
            if args.encode_runtime:
                _encode_runtime(wav_path, args.output_root / "bgm" / f"{name}.m4a")

        for name, (duration, sampler) in _sfx_samplers().items():
            if selected and name not in selected:
                continue
            wav_path = temp_root / f"{name}.wav" if args.encode_runtime else args.output_root / "sfx" / f"{name}.wav"
            _write_wav(wav_path, duration, sampler)
            if args.encode_runtime:
                _encode_runtime(wav_path, args.output_root / "sfx" / f"{name}.m4a")


if __name__ == "__main__":
    main()
