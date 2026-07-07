class FlutterDevice {
  const FlutterDevice({
    required this.id,
    required this.name,
    required this.platform,
    this.emulator = false,
    this.sdk,
  });

  final String id;
  final String name;
  final String platform;
  final bool emulator;
  final String? sdk;

  factory FlutterDevice.fromJson(Map<String, dynamic> json) {
    return FlutterDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      platform: json['platform'] as String? ?? 'unknown',
      emulator: json['emulator'] as bool? ?? false,
      sdk: json['sdk'] as String?,
    );
  }

  String get subtitle {
    final parts = <String>[
      platform,
      if (emulator) 'emulator',
      if (sdk != null && sdk!.isNotEmpty) sdk!,
    ];
    return parts.join(' · ');
  }
}

class FlutterDevicesResponse {
  const FlutterDevicesResponse({
    required this.devices,
    this.preferredDeviceId,
  });

  final List<FlutterDevice> devices;
  final String? preferredDeviceId;

  factory FlutterDevicesResponse.fromJson(Map<String, dynamic> json) {
    final devices = json['devices'];
    return FlutterDevicesResponse(
      devices: devices is List
          ? devices
              .map(
                (device) => FlutterDevice.fromJson(
                  Map<String, dynamic>.from(device as Map),
                ),
              )
              .toList()
          : const [],
      preferredDeviceId: json['preferredDeviceId'] as String?,
    );
  }
}
