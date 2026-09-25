// Stub implementations for dart:html when not on web platforms

class Blob {
  final List<Object> data;
  final String? mimeType;

  Blob(this.data, [this.mimeType]);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) {
    // Stub: return a dummy URL
    return 'stub://blob';
  }

  static void revokeObjectUrl(String url) {
    // Stub: do nothing
  }
}

class AnchorElement {
  String? href;
  String? download;

  void setAttribute(String name, String value) {
    // Stub: do nothing
  }

  void click() {
    // Stub: do nothing
  }
}

class Window {
  static Window? get window => null;

  void open(String url, String target) {
    // Stub: do nothing
  }
}

final window = Window();
