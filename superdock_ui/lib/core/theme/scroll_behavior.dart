import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// macOS scrollar som standard bara med mus — inte touch från iPad som andra skärm.
class SuperDockScrollBehavior extends MaterialScrollBehavior {
  const SuperDockScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}
