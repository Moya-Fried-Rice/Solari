#!/usr/bin/env python3
"""
Generate clean, static-free 8kHz A-Law compressed WAV file for smart glasses
Focus on smooth waveforms and proper A-Law compression
"""

import wave
import numpy as np
import struct

def linear_to_alaw(sample):
    """
    Convert a 16-bit linear PCM sample to A-Law compressed format
    """
    # Clamp to 16-bit range
    sample = max(-32768, min(32767, int(sample)))
    
    # Get sign and magnitude
    sign = 0 if sample >= 0 else 0x80
    if sample < 0:
        sample = -sample
    
    # Find the segment and quantization interval
    if sample >= 32635:
        return sign | 0x7F
    elif sample >= 16318:
        seg = 7
    elif sample >= 8159:
        seg = 6
    elif sample >= 4079:
        seg = 5
    elif sample >= 2039:
        seg = 4
    elif sample >= 1019:
        seg = 3
    elif sample >= 509:
        seg = 2
    elif sample >= 254:
        seg = 1
    else:
        seg = 0
    
    if seg >= 1:
        sample = (sample >> (seg + 3)) & 0x0F
    else:
        sample = sample >> 4
    
    return sign | (seg << 4) | sample

def create_alaw_wav_header(sample_rate, num_samples):
    """
    Create a proper WAV header for A-Law compressed audio
    """
    # WAV header structure for A-Law
    header = bytearray()
    
    # RIFF header
    header.extend(b'RIFF')
    header.extend(struct.pack('<I', 36 + num_samples))  # File size - 8
    header.extend(b'WAVE')
    
    # Format chunk
    header.extend(b'fmt ')
    header.extend(struct.pack('<I', 18))  # Format chunk size (18 for A-Law)
    header.extend(struct.pack('<H', 6))   # Format code: 6 = A-Law
    header.extend(struct.pack('<H', 1))   # Channels: 1 (mono)
    header.extend(struct.pack('<I', sample_rate))  # Sample rate
    header.extend(struct.pack('<I', sample_rate))  # Byte rate (same as sample rate for A-Law)
    header.extend(struct.pack('<H', 1))   # Block align: 1 byte per sample
    header.extend(struct.pack('<H', 8))   # Bits per sample: 8
    header.extend(struct.pack('<H', 0))   # Extra format bytes
    
    # Data chunk
    header.extend(b'data')
    header.extend(struct.pack('<I', num_samples))  # Data size
    
    return header

def create_clean_alaw_wav(filename="clean_alaw.wav", duration=3.0):
    """
    Create a very clean 8kHz, A-Law compressed, mono WAV file
    
    A-Law provides better dynamic range than 8-bit PCM and is optimized
    for voice applications like smart glasses
    """
    
    sample_rate = 8000  # 8kHz
    duration_sec = duration
    
    # Generate time array
    t = np.linspace(0, duration_sec, int(sample_rate * duration_sec), False)
    
    # Create a smooth, clean audio signal
    # Use a fundamental frequency that's pleasant and clear
    fundamental = 220.0  # A3 note - pleasant frequency
    
    # Build a clean harmonic series (no harsh overtones)
    audio = (
        0.6 * np.sin(2 * np.pi * fundamental * t) +           # Fundamental (strong)
        0.3 * np.sin(2 * np.pi * fundamental * 2 * t) +       # Octave (pleasant)
        0.15 * np.sin(2 * np.pi * fundamental * 3 * t) +      # Perfect fifth
        0.075 * np.sin(2 * np.pi * fundamental * 4 * t)       # Double octave
    )
    
    # Add gentle amplitude modulation (vibrato effect)
    modulation = 1.0 + 0.1 * np.sin(2 * np.pi * 4.0 * t)  # 4Hz vibrato
    audio = audio * modulation
    
    # Apply smooth fade in and fade out to prevent clicks
    fade_samples = int(0.1 * sample_rate)  # 100ms fade
    
    # Fade in
    fade_in = np.linspace(0, 1, fade_samples)
    audio[:fade_samples] *= fade_in
    
    # Fade out
    fade_out = np.linspace(1, 0, fade_samples)
    audio[-fade_samples:] *= fade_out
    
    # Normalize very carefully to prevent clipping and distortion
    max_amplitude = np.max(np.abs(audio))
    if max_amplitude > 0:
        audio = audio / max_amplitude * 0.8  # Leave some headroom
    
    # Convert to 16-bit signed for A-Law conversion
    audio_16bit = (audio * 32767).astype(np.int16)
    
    # Convert each sample to A-Law
    alaw_data = bytearray()
    for sample in audio_16bit:
        alaw_sample = linear_to_alaw(sample)
        alaw_data.append(alaw_sample)
    
    # Create A-Law WAV file with proper header
    header = create_alaw_wav_header(sample_rate, len(alaw_data))
    
    with open(filename, 'wb') as f:
        f.write(header)
        f.write(alaw_data)
    
    file_size = len(header) + len(alaw_data)
    print(f"Created CLEAN A-LAW {filename}:")
    print(f"  Sample Rate: {sample_rate} Hz")
    print(f"  Format: A-Law compressed (8-bit logarithmic)")
    print(f"  Channels: 1 (mono)")
    print(f"  Duration: {duration_sec:.1f} seconds")
    print(f"  File Size: {file_size} bytes ({file_size/1024:.1f} KB)")
    print(f"  Data Size: {len(alaw_data)} bytes")
    print(f"  Frequency: {fundamental} Hz (A3 note)")
    print(f"  ✅ A-Law optimized for smart glasses")
    
    return filename

def create_speech_like_alaw_wav(filename="speech_clean_alaw.wav", duration=3.0):
    """
    Create a speech-like clean A-Law audio for better smart glasses testing
    """
    
    sample_rate = 8000
    duration_sec = duration
    
    t = np.linspace(0, duration_sec, int(sample_rate * duration_sec), False)
    
    # Create speech-like formants (vowel sounds)
    # These frequencies are common in human speech
    f1 = 800   # First formant (vowel character)
    f2 = 1200  # Second formant (vowel character)
    f3 = 2400  # Third formant (consonant clarity)
    
    # Generate clean speech-like audio
    audio = (
        0.4 * np.sin(2 * np.pi * 150 * t) +          # Fundamental voice frequency
        0.3 * np.sin(2 * np.pi * f1 * t) +           # First formant
        0.2 * np.sin(2 * np.pi * f2 * t) +           # Second formant  
        0.1 * np.sin(2 * np.pi * f3 * t)             # Third formant
    )
    
    # Add natural speech-like amplitude variation
    envelope = 0.5 + 0.5 * np.sin(2 * np.pi * 3 * t) * np.exp(-0.5 * (t % 1.0))
    audio = audio * envelope
    
    # Smooth fade in/out
    fade_samples = int(0.05 * sample_rate)  # 50ms fade
    fade_in = np.linspace(0, 1, fade_samples)
    fade_out = np.linspace(1, 0, fade_samples)
    
    audio[:fade_samples] *= fade_in
    audio[-fade_samples:] *= fade_out
    
    # Careful normalization
    max_amplitude = np.max(np.abs(audio))
    if max_amplitude > 0:
        audio = audio / max_amplitude * 0.75
    
    # Convert to 16-bit signed for A-Law conversion
    audio_16bit = (audio * 32767).astype(np.int16)
    
    # Convert each sample to A-Law
    alaw_data = bytearray()
    for sample in audio_16bit:
        alaw_sample = linear_to_alaw(sample)
        alaw_data.append(alaw_sample)
    
    # Create A-Law WAV file with proper header
    header = create_alaw_wav_header(sample_rate, len(alaw_data))
    
    with open(filename, 'wb') as f:
        f.write(header)
        f.write(alaw_data)
    
    file_size = len(header) + len(alaw_data)
    print(f"\nCreated SPEECH-LIKE A-LAW {filename}:")
    print(f"  Sample Rate: {sample_rate} Hz")
    print(f"  Format: A-Law compressed")
    print(f"  Duration: {duration_sec:.1f} seconds")
    print(f"  File Size: {file_size} bytes ({file_size/1024:.1f} KB)")
    print(f"  Data Size: {len(alaw_data)} bytes")
    print(f"  ✅ Speech-like formants with A-Law compression")
    
    return filename

if __name__ == "__main__":
    print("Creating clean, static-free A-Law compressed WAV files...\n")
    
    # Create a clean musical tone with A-Law compression
    clean_file = create_clean_alaw_wav("clean_alaw.wav", duration=3.0)
    
    # Create a speech-like test file with A-Law compression
    speech_file = create_speech_like_alaw_wav("speech_clean_alaw.wav", duration=3.0)
    
    # Also create a test.wav file (copy of the clean one for direct testing)
    test_file = create_clean_alaw_wav("test.wav", duration=2.0)
    
    print(f"\n✅ Created A-Law compressed files!")
    print(f"📁 Copy 'test.wav' to SD card for immediate testing")
    print(f"🎵 {clean_file} - Clean musical tone (A-Law)")
    print(f"🗣️  {speech_file} - Speech-like audio (A-Law)")
    print(f"🧪 {test_file} - Ready to test (A-Law)")
    print(f"\n🔊 Format: 8kHz, A-Law compressed, mono")
    print(f"📱 Compatible with updated Arduino smart glasses code")
