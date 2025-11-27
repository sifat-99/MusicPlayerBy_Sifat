import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sifat_audio/providers/audio_provider.dart';

class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Audio Effects"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Colors.black,
            ],
          ),
        ),
        child: Consumer<AudioProvider>(
          builder: (context, audioProvider, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                Text(
                  "Playback Speed: ${audioProvider.speed.toStringAsFixed(1)}x",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                Slider(
                  value: audioProvider.speed,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: "${audioProvider.speed.toStringAsFixed(1)}x",
                  onChanged: (value) {
                    audioProvider.setSpeed(value);
                  },
                ),
                const SizedBox(height: 40),
                Text(
                  "Pitch: ${audioProvider.pitch.toStringAsFixed(1)}x",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                Slider(
                  value: audioProvider.pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: "${audioProvider.pitch.toStringAsFixed(1)}x",
                  onChanged: (value) {
                    audioProvider.setPitch(value);
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    audioProvider.setSpeed(1.0);
                    audioProvider.setPitch(1.0);
                  },
                  child: const Text("Reset to Normal"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
