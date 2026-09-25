// Web implementation — manipulates the live DOM via dart:js
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class SeoService {
  SeoService._();

  /// Call from `initState` on any web screen to update the browser tab title
  /// and the `<meta name="description">` tag for that route.
  static void setPage({
    required String title,
    String description =
        "EventEase — Malaysia's #1 event planning platform.",
  }) {
    try {
      js.context['document']['title'] = title;
      _setMeta('description', description);
      _setMeta('twitter:title', title);
      _setMeta('twitter:description', description);
      _setOg('og:title', title);
      _setOg('og:description', description);
    } catch (_) {
      // Silently swallow any JS-interop errors
    }
  }

  static void _setMeta(String name, String content) {
    final els =
        js.context['document'].callMethod('querySelectorAll', ['meta[name="$name"]']);
    if (els['length'] > 0) {
      els[0]['content'] = content;
    } else {
      final el = js.context['document'].callMethod('createElement', ['meta']);
      el['name'] = name;
      el['content'] = content;
      js.context['document']['head'].callMethod('appendChild', [el]);
    }
  }

  static void _setOg(String property, String content) {
    final els = js.context['document']
        .callMethod('querySelectorAll', ['meta[property="$property"]']);
    if (els['length'] > 0) {
      els[0]['content'] = content;
    } else {
      final el = js.context['document'].callMethod('createElement', ['meta']);
      el.callMethod('setAttribute', ['property', property]);
      el['content'] = content;
      js.context['document']['head'].callMethod('appendChild', [el]);
    }
  }
}
