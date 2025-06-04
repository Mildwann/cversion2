import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraSettingsPanel extends StatefulWidget {
  final ResolutionPreset currentResolution;
  final void Function(ResolutionPreset) onResolutionChanged;

  const CameraSettingsPanel({
    super.key,
    required this.currentResolution,
    required this.onResolutionChanged,
  });

  @override
  State<CameraSettingsPanel> createState() => _CameraSettingsPanelState();
}

class _CameraSettingsPanelState extends State<CameraSettingsPanel> {
  late ResolutionPreset selectedResolution;
  String? selectedAspectRatio;

  final Map<String, List<ResolutionPreset>> aspectRatioMap = {
    '4:3': [ResolutionPreset.low],
    '3:2': [ResolutionPreset.medium],
    '16:9': [
      ResolutionPreset.high,
      ResolutionPreset.veryHigh,
      ResolutionPreset.ultraHigh
    ],
    'Max': [ResolutionPreset.max],
  };

  String resolutionToString(ResolutionPreset preset) {
    switch (preset) {
      case ResolutionPreset.low:
        return '320x240';
      case ResolutionPreset.medium:
        return '720x480';
      case ResolutionPreset.high:
        return '1280x720';
      case ResolutionPreset.veryHigh:
        return '1920x1080';
      case ResolutionPreset.ultraHigh:
        return '3840x2160';
      case ResolutionPreset.max:
        return 'Max (device dependent)';
      }
  }

  @override
  void initState() {
    super.initState();
    selectedResolution = widget.currentResolution;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 49, 50, 54),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aspect Ratio',
              style: TextStyle(
                color: Color(0xFFEEEEEE),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: aspectRatioMap.keys.map((ratio) {
                final isSelected = selectedAspectRatio == ratio;
                return ChoiceChip(
                  label: Text(
                    ratio,
                    style: TextStyle(
                      color: isSelected ? const Color.fromARGB(255, 255, 255, 255) : Colors.grey[300],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.blueAccent,
                  backgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                     side: BorderSide(
      color: isSelected ? Colors.blueAccent : const Color.fromARGB(255, 80, 79, 79),
      width: 1,
    ),
                  ),
                  onSelected: (_) {
                    setState(() {
                      selectedAspectRatio = ratio;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            if (selectedAspectRatio != null) ...[
              Text(
                'Resolution (${selectedAspectRatio!})',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: aspectRatioMap[selectedAspectRatio]!.map((preset) {
                  final isSelected = preset == selectedResolution;
                  return ChoiceChip(
                    label: Text(
                      resolutionToString(preset),
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.grey[300],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Color.fromARGB(255, 138, 196, 217),
                    backgroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                                     side: BorderSide(
      color: isSelected ? Color.fromARGB(255, 138, 196, 217) : const Color.fromARGB(255, 80, 79, 79),
      width: 1,
    )
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedResolution = preset;
                        });
                        widget.onResolutionChanged(preset);
                      }
                    },
                  );
                }).toList(),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
