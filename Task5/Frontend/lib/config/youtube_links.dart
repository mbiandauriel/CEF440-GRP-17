/// Curated YouTube tutorial URLs for demo fault codes.
///
/// Replace each placeholder with a full watch URL, e.g.
/// https://www.youtube.com/watch?v=XXXXXXXXXXX
///
/// Suggested search queries:
/// - P0300: "P0300 random misfire fix spark plugs"
/// - P0420: "P0420 catalytic converter oxygen sensor fix"
/// - P0171: "P0171 system too lean bank 1 fix"
/// - P0442: "P0442 evap small leak gas cap fix"
/// - P0128: "P0128 coolant thermostat replacement"
const Map<String, String> youtubeLinks = {
  'P0300': 'https://youtu.be/Pbz9wDtMuoU?si=EgIJiB8FhKHgV3MN', // Cylinder misfire — spark plugs / ignition coils
  'P0420': '', // Catalytic converter efficiency
  'P0171': '', // System too lean bank 1
  'P0442': '', // EVAP small leak
  'P0128': '', // Coolant thermostat
};

String? youtubeUrlForCode(String code) {
  final url = youtubeLinks[code.toUpperCase()];
  if (url == null || url.isEmpty) return null;
  return url;
}

bool hasYoutubeTutorial(String code) => youtubeUrlForCode(code) != null;
