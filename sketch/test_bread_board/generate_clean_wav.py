#!/usr/bin/env python3
"""
Generate clean, static-free 8kHz 8-bit WAV file for smart glasses
Focus on smooth waveforms and proper amplitude scaling
"""

import wave
import numpy as np

def create_clean_8bit_wav(filename="clean_8bit.wav", duration=3.0):
    """
    Create a very clean 8kHz, 8-bit, mono WAV file with no static
    
    Improvements for static reduction:
    - Smoother waveform transitions
    - Proper amplitude scaling
    - No harsh frequency jumps
    - Clean sine wave generation
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
    
    # Convert to 8-bit unsigned with proper rounding
    # This is critical for avoiding static
    audio_8bit = np.clip((audio + 1.0) * 127.5 + 0.5, 0, 255).astype(np.uint8)
    
    # Create WAV file
    with wave.open(filename, 'w') as wav_file:
        wav_file.setparams((1, 1, sample_rate, len(audio_8bit), 'NONE', 'not compressed'))
        wav_file.writeframes(audio_8bit.tobytes())
    
    file_size = len(audio_8bit)
    print(f"Created CLEAN {filename}:")
    print(f"  Sample Rate: {sample_rate} Hz")
    print(f"  Bit Depth: 8-bit unsigned")
    print(f"  Channels: 1 (mono)")
    print(f"  Duration: {duration_sec:.1f} seconds")
    print(f"  File Size: {file_size} bytes ({file_size/1024:.1f} KB)")
    print(f"  Frequency: {fundamental} Hz (A3 note)")
    print(f"  ✅ Optimized for no static or distortion")
    
    return filename

def create_speech_like_clean_wav(filename="speech_clean_8bit.wav", duration=3.0):
    """
    Create a speech-like clean audio for better smart glasses testing
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
    
    # High-quality 8-bit conversion
    audio_8bit = np.clip((audio + 1.0) * 127.5 + 0.5, 0, 255).astype(np.uint8)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setparams((1, 1, sample_rate, len(audio_8bit), 'NONE', 'not compressed'))
        wav_file.writeframes(audio_8bit.tobytes())
    
    file_size = len(audio_8bit)
    print(f"\nCreated SPEECH-LIKE {filename}:")
    print(f"  Sample Rate: {sample_rate} Hz")
    print(f"  Duration: {duration_sec:.1f} seconds")
    print(f"  File Size: {file_size} bytes ({file_size/1024:.1f} KB)")
    print(f"  ✅ Speech-like formants for smart glasses testing")
    
    return filename

if __name__ == "__main__":
    print("Creating clean, static-free 8-bit WAV files...\n")
    
    # Create a clean musical tone
    clean_file = create_clean_8bit_wav("clean_8bit.wav", duration=3.0)
    
    # Create a speech-like test file
    speech_file = create_speech_like_clean_wav("speech_clean_8bit.wav", duration=3.0)
    
    print(f"\n✅ Created both files!")
    print(f"📁 Copy either file to SD card as 'test.wav'")
    print(f"🎵 {clean_file} - Clean musical tone")
    print(f"🗣️  {speech_file} - Speech-like audio")
