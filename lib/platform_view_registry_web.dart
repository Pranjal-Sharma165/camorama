// platform_view_registry_web.dart
import 'dart:ui' as ui;

void registerViewFactory(String viewTypeId, dynamic viewFactory) {
  ui.platformViewRegistry.registerViewFactory(viewTypeId, viewFactory);
}
