// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final outDir = Directory('assets/audio');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  File('${outDir.path}/flap.wav').writeAsBytesSync(generateFlap());
  File('${outDir.path}/score.wav').writeAsBytesSync(generateScore());
  File('${outDir.path}/hit.wav').writeAsBytesSync(generateHit());
  File('${outDir.path}/coin.wav').writeAsBytesSync(generateCoin());
  File('${outDir.path}/powerup.wav').writeAsBytesSync(generatePowerup());
  File('${outDir.path}/complete.wav').writeAsBytesSync(generateComplete());
  File('${outDir.path}/click.wav').writeAsBytesSync(generateClick());
  File('${outDir.path}/penguin_die.wav').writeAsBytesSync(generatePenguinDie());

  print('Audio assets generated successfully in ${outDir.path}!');
}

Uint8List createWav(List<double> samples, {int sampleRate = 44100}) {
  final byteData = ByteData(44 + samples.length * 2);

  // "RIFF"
  byteData.setUint8(0, 0x52);
  byteData.setUint8(1, 0x49);
  byteData.setUint8(2, 0x46);
  byteData.setUint8(3, 0x46);

  // File size - 8
  final fileSize = 36 + samples.length * 2;
  byteData.setUint32(4, fileSize, Endian.little);

  // "WAVE"
  byteData.setUint8(8, 0x57);
  byteData.setUint8(9, 0x41);
  byteData.setUint8(10, 0x56);
  byteData.setUint8(11, 0x45);

  // "fmt "
  byteData.setUint8(12, 0x66);
  byteData.setUint8(13, 0x6D);
  byteData.setUint8(14, 0x74);
  byteData.setUint8(15, 0x20);

  byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
  byteData.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
  byteData.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
  byteData.setUint32(24, sampleRate, Endian.little); // SampleRate
  byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
  byteData.setUint16(32, 2, Endian.little); // BlockAlign (NumChannels * BitsPerSample/8)
  byteData.setUint16(34, 16, Endian.little); // BitsPerSample (16)

  // "data"
  byteData.setUint8(36, 0x64);
  byteData.setUint8(37, 0x61);
  byteData.setUint8(38, 0x74);
  byteData.setUint8(39, 0x61);

  byteData.setUint32(40, samples.length * 2, Endian.little);

  int offset = 44;
  for (final s in samples) {
    final clamped = s.clamp(-1.0, 1.0);
    final intVal = (clamped * 32767).toInt();
    byteData.setInt16(offset, intVal, Endian.little);
    offset += 2;
  }

  return byteData.buffer.asUint8List();
}

Uint8List generateFlap() {
  const sampleRate = 44100;
  final duration = 0.15; // 150ms
  final totalSamples = (duration * sampleRate).toInt();
  final samples = <double>[];

  double phase = 0.0;
  for (int i = 0; i < totalSamples; i++) {
    final t = i / totalSamples;
    // Pitch sweep upward from 320 Hz to 680 Hz then drop
    final freq = 320 + 360 * sin(t * pi);
    phase += 2 * pi * freq / sampleRate;

    // Triangle / sine mix with soft attack and decay
    final sine = sin(phase);
    final envelope = sin(t * pi) * (1.0 - t * 0.3);
    samples.add(sine * envelope * 0.7);
  }
  return createWav(samples);
}

Uint8List generateScore() {
  const sampleRate = 44100;
  final duration = 0.28;
  final totalSamples = (duration * sampleRate).toInt();
  final samples = <double>[];

  double phase1 = 0;
  double phase2 = 0;
  for (int i = 0; i < totalSamples; i++) {
    final t = i / totalSamples;
    // Two-tone bell chime: first 120ms at 880Hz (A5), second at 1320Hz (E6)
    final freq = t < 0.45 ? 880.0 : 1320.0;
    final decay = t < 0.45 ? exp(-t * 12) : exp(-(t - 0.45) * 10);

    phase1 += 2 * pi * freq / sampleRate;
    phase2 += 2 * pi * (freq * 2.0) / sampleRate;

    final signal = sin(phase1) + 0.3 * sin(phase2);
    samples.add(signal * decay * 0.6);
  }
  return createWav(samples);
}

Uint8List generateHit() {
  const sampleRate = 44100;
  final duration = 0.35;
  final totalSamples = (duration * sampleRate).toInt();
  final samples = <double>[];
  final rnd = Random(42);

  double phase = 0;
  for (int i = 0; i < totalSamples; i++) {
    final t = i / totalSamples;
    // Rapid downward pitch sweep: 280 Hz down to 40 Hz
    final freq = 280 * exp(-t * 7) + 40;
    phase += 2 * pi * freq / sampleRate;

    final tone = sin(phase);
    final noise = (rnd.nextDouble() * 2 - 1) * exp(-t * 9);
    final envelope = exp(-t * 6);

    samples.add((tone * 0.6 + noise * 0.4) * envelope * 0.8);
  }
  return createWav(samples);
}

Uint8List generateCoin() {
  const sampleRate = 44100;
  final duration = 0.35;
  final totalSamples = (duration * sampleRate).toInt();
  final samples = <double>[];

  double phase1 = 0;
  double phase2 = 0;
  for (int i = 0; i < totalSamples; i++) {
    final t = i / totalSamples;
    // Classic arcade coin chime: First tone B5 (987.77 Hz), second tone high E6 (1318.51 Hz)
    final freq = t < 0.22 ? 987.77 : 1318.51;
    final decay = t < 0.22 ? (1.0 - t / 0.22 * 0.2) : exp(-(t - 0.22) * 8);

    phase1 += 2 * pi * freq / sampleRate;
    phase2 += 2 * pi * (freq * 2.0) / sampleRate;

    final signal = sin(phase1) * 0.85 + sin(phase2) * 0.25;
    samples.add(signal * decay * 0.95);
  }
  return createWav(samples);
}

Uint8List generatePowerup() {
  const sampleRate = 44100;
  final duration = 0.45;
  final totalSamples = (duration * sampleRate).toInt();
  final samples = <double>[];

  // 4 notes arpeggio: C5 (523), E5 (659), G5 (784), C6 (1046)
  final notes = [523.25, 659.25, 783.99, 1046.50];
  double phase = 0;

  for (int i = 0; i < totalSamples; i++) {
    final t = i / duration / sampleRate; // current time in sec
    final noteIdx = ((i / totalSamples) * notes.length).floor().clamp(0, notes.length - 1);
    final freq = notes[noteIdx];
    phase += 2 * pi * freq / sampleRate;

    final vibrato = sin(2 * pi * 8 * t) * 0.05;
    final envelope = (1.0 - (i / totalSamples) * 0.3);
    final sample = (sin(phase) + 0.3 * sin(phase * 1.5)) * envelope * (0.6 + vibrato);
    samples.add(sample * 0.6);
  }
  return createWav(samples);
}

Uint8List generateComplete() {
  const sampleRate = 44100;
  final duration = 0.75;
  final totalSamples = (duration * sampleRate).toInt();
  final samples = <double>[];

  // Joyful fanfare: G5, C6, E6, G6
  final notes = [783.99, 1046.50, 1318.51, 1567.98];
  double phase1 = 0;
  double phase2 = 0;

  for (int i = 0; i < totalSamples; i++) {
    final noteIdx = ((i / totalSamples) * notes.length).floor().clamp(0, notes.length - 1);
    final freq = notes[noteIdx];
    phase1 += 2 * pi * freq / sampleRate;
    phase2 += 2 * pi * (freq * 0.5) / sampleRate; // sub-octave warmth

    final noteProgress = ((i / totalSamples) * notes.length) - noteIdx;
    final decay = exp(-noteProgress * 4);
    final val = (sin(phase1) * 0.7 + sin(phase2) * 0.3) * (0.5 + 0.5 * decay);
    samples.add(val * 0.6);
  }
  return createWav(samples);
}

Uint8List generateClick() {
  const sampleRate = 44100;
  final duration = 0.04; // 40ms
  final totalSamples = (duration * sampleRate).toInt();
  final samples = <double>[];

  double phase = 0;
  for (int i = 0; i < totalSamples; i++) {
    final t = i / totalSamples;
    final freq = 1200 * exp(-t * 15);
    phase += 2 * pi * freq / sampleRate;

    final envelope = (1.0 - t);
    samples.add(sin(phase) * envelope * 0.5);
  }
  return createWav(samples);
}

Uint8List generatePenguinDie() {
  const sampleRate = 44100;
  final duration = 0.52; // 520ms
  final totalSamples = (duration * sampleRate).toInt();
  final samples = <double>[];
  final rnd = Random(77);

  double phase1 = 0;
  double phase2 = 0;
  double noisePhase = 0;

  for (int i = 0; i < totalSamples; i++) {
    final timeSec = i / sampleRate;

    // Part 1: Initial bump impact (0 to 60ms)
    double impact = 0.0;
    if (timeSec < 0.06) {
      final impactT = timeSec / 0.06;
      final impactFreq = 220 * exp(-impactT * 8) + 50;
      noisePhase += 2 * pi * impactFreq / sampleRate;
      final noise = (rnd.nextDouble() * 2 - 1) * exp(-impactT * 10);
      impact = (sin(noisePhase) * 0.7 + noise * 0.5) * (1.0 - impactT);
    }

    // Part 2: Comical penguin squawk (Wenk! / Waaak!)
    double squawk = 0.0;
    if (timeSec > 0.03) {
      final sqT = (timeSec - 0.03) / (duration - 0.03);
      // Pitch trajectory: sweeps from 460 Hz up to 740 Hz, then slides down to 310 Hz
      final baseFreq = sqT < 0.25
          ? (460 + 280 * (sqT / 0.25))
          : (740 * exp(-(sqT - 0.25) * 2.2));

      // Nasal Penguin Formant: dual pitch with a 38 Hz raspy throat flutter
      final flutter = 1.0 + 0.12 * sin(2 * pi * 38 * timeSec);
      final freq1 = baseFreq * flutter;
      final freq2 = baseFreq * 1.58 * flutter;

      phase1 += 2 * pi * freq1 / sampleRate;
      phase2 += 2 * pi * freq2 / sampleRate;

      // Penguin squawk timbre: resonant clipped sine mix
      final rawTone = sin(phase1) * 0.7 + sin(phase2) * 0.35;
      final raspyTone = rawTone.clamp(-0.8, 0.8) * 1.25;

      // Envelope: fast attack, sustains briefly, then decays
      final envelope = sqT < 0.15
          ? (sqT / 0.15)
          : exp(-(sqT - 0.15) * 4.5);

      squawk = raspyTone * envelope;
    }

    final combined = (impact * 0.75 + squawk * 0.9).clamp(-1.0, 1.0);
    samples.add(combined);
  }
  return createWav(samples);
}
