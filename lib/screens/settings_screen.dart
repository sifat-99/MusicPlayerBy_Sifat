import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sifat_audio/providers/settings_provider.dart';
import 'package:sifat_audio/providers/theme_provider.dart';
import 'package:sifat_audio/providers/audio_provider.dart';
import 'package:sifat_audio/screens/equalizer_screen.dart';
import 'package:path/path.dart' as p;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
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
        child: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return ListView(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight,
              ),
              children: [
                _buildSectionHeader(context, "Appearance"),
                _buildListTile(
                  context,
                  icon: Icons.color_lens,
                  title: "Application Appearance",
                  subtitle: "Change app theme color",
                  onTap: () => _showColorPicker(context),
                ),
                _buildListTile(
                  context,
                  icon: Icons.text_fields,
                  title: "Font Size",
                  subtitle: "Scale: ${(settings.fontSize * 100).toInt()}%",
                  onTap: () => _showFontSizeDialog(context, settings),
                ),

                _buildSectionHeader(context, "Player UI"),
                _buildListTile(
                  context,
                  icon: Icons.aspect_ratio,
                  title: "Full Player UI",
                  subtitle: "Customize player layout (Coming Soon)",
                  onTap: () {},
                ),
                _buildListTile(
                  context,
                  icon: Icons.lyrics,
                  title: "Lyrics",
                  subtitle: settings.showLyrics ? "Shown" : "Hidden",
                  trailing: Switch(
                    value: settings.showLyrics,
                    onChanged: (v) => settings.setShowLyrics(v),
                  ),
                ),

                _buildSectionHeader(context, "Behavior"),
                _buildListTile(
                  context,
                  icon: Icons.filter_list,
                  title: "Filters",
                  subtitle: "Min Duration: ${settings.minDuration}s",
                  onTap: () => _showDurationDialog(context, settings),
                ),
                _buildListTile(
                  context,
                  icon: Icons.launch,
                  title: "Launch Behaviors",
                  subtitle: "Auto-play on start",
                  trailing: Switch(
                    value: settings.autoPlay,
                    onChanged: (v) => settings.setAutoPlay(v),
                  ),
                ),

                _buildSectionHeader(context, "File Permission"),
                _buildListTile(
                  context,
                  icon: Icons.folder_open,
                  title: "Permission Manager",
                  subtitle: "Manage storage access",
                  onTap: () => openAppSettings(),
                ),
                _buildListTile(
                  context,
                  icon: Icons.create_new_folder,
                  title: "Ignored Paths",
                  subtitle: "Select folders to ignore",
                  onTap: () => _showIgnoredPathsDialog(context, settings),
                ),

                _buildSectionHeader(context, "Audio"),
                _buildListTile(
                  context,
                  icon: Icons.equalizer,
                  title: "Audio Effects",
                  subtitle: "Playback Speed & Pitch",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EqualizerScreen()),
                  ),
                ),
                _buildListTile(
                  context,
                  icon: Icons.high_quality,
                  title: "Output Quality",
                  subtitle: settings.audioQuality,
                  onTap: () => _showQualityDialog(context, settings),
                ),
                _buildListTile(
                  context,
                  icon: Icons.settings_voice,
                  title: "Misc",
                  subtitle: "Other audio settings",
                  onTap: () {},
                ),

                _buildSectionHeader(context, "About"),
                _buildListTile(
                  context,
                  icon: Icons.info,
                  title: "About App",
                  subtitle: "Version 1.0.0",
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: "Sifat Audio",
                    applicationVersion: "1.0.0",
                    applicationLegalese: "© 2024 Sifat Dev",
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                [
                  Colors.deepPurple,
                  Colors.blue,
                  Colors.red,
                  Colors.green,
                  Colors.orange,
                  Colors.pink,
                  Colors.teal,
                  Colors.indigo,
                ].map((color) {
                  return GestureDetector(
                    onTap: () {
                      Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).setPrimaryColor(color);
                      Navigator.pop(context);
                    },
                    child: CircleAvatar(backgroundColor: color, radius: 20),
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  void _showDurationDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(
      text: settings.minDuration.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Minimum Song Duration (seconds)"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "e.g. 30"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text) ?? 0;
              settings.setMinDuration(val);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showQualityDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Select Audio Quality"),
        children: ["High", "Medium", "Low"].map((q) {
          return SimpleDialogOption(
            onPressed: () {
              settings.setAudioQuality(q);
              Navigator.pop(context);
            },
            child: Text(q),
          );
        }).toList(),
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context, SettingsProvider settings) {
    double tempSize = settings.fontSize;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Adjust Font Size"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Preview Text",
                    style: TextStyle(fontSize: 16 * tempSize),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: tempSize,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    label: "${(tempSize * 100).toInt()}%",
                    onChanged: (value) {
                      setState(() {
                        tempSize = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    settings.setFontSize(tempSize);
                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showIgnoredPathsDialog(
    BuildContext context,
    SettingsProvider settings,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Ignored Paths"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (settings.ignoredPaths.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("No ignored paths"),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: settings.ignoredPaths.length,
                          itemBuilder: (context, index) {
                            final path = settings.ignoredPaths[index];
                            return ListTile(
                              title: Text(
                                path,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  settings.removeIgnoredPath(path);
                                  setState(() {}); // Refresh dialog
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showAddPathDialog(context, settings, setState);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Add Path"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddPathDialog(
    BuildContext context,
    SettingsProvider settings,
    StateSetter parentSetState,
  ) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final folders = audioProvider.folders.keys.toList();

    // Filter out already ignored paths
    final availableFolders = folders
        .where((path) => !settings.ignoredPaths.contains(path))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Folder to Ignore"),
        content: SizedBox(
          width: double.maxFinite,
          child: availableFolders.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("No new folders found to ignore."),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableFolders.length,
                  itemBuilder: (context, index) {
                    final path = availableFolders[index];
                    final folderName = p.basename(path);
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(folderName),
                      subtitle: Text(
                        path,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      onTap: () {
                        settings.addIgnoredPath(path);
                        parentSetState(() {}); // Refresh parent dialog
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }
}
