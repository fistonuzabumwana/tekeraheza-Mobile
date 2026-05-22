import 'package:url_launcher/url_launcher.dart';

Future<bool> openInMaps({
  double? latitude,
  double? longitude,
  String? addressQuery,
}) async {
  final Uri uri;
  if (latitude != null && longitude != null) {
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
  } else if (addressQuery != null && addressQuery.trim().isNotEmpty) {
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(addressQuery.trim())}',
    );
  } else {
    return false;
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
