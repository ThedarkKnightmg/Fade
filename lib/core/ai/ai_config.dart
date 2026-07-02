/// Configuration for the realistic hair-editing AI.
///
/// The app itself ships with NO key. To turn on photo-real hair generation,
/// fill in [endpoint] + [apiKey] (and rebuild). The endpoint must accept the
/// request shape produced by `HairAiService` and return an edited image.
///
/// Why a configurable endpoint instead of a hard-coded provider:
///  • Realistic hair replacement is a generative-AI image task — it cannot run
///    on-device, so the app calls a cloud service at runtime.
///  • Calling a 3rd-party API straight from the client leaks the key and is
///    usually blocked by CORS on web. The recommended setup is a tiny proxy
///    you host (e.g. a serverless function) that holds the real provider key
///    and forwards to Replicate / Stability / an AI-hairstyle API. Point
///    [endpoint] at that proxy.
class AiConfig {
  AiConfig._();

  /// Your hair-edit endpoint (your proxy, or a provider that allows direct
  /// calls). Leave empty to keep the AI disabled.
  static const String endpoint = String.fromEnvironment(
    'HAIR_AI_ENDPOINT',
    defaultValue: '',
  );

  /// Bearer token / API key sent as `Authorization: Bearer <key>`.
  static const String apiKey = String.fromEnvironment(
    'HAIR_AI_KEY',
    defaultValue: '',
  );

  /// True when both an endpoint and a key are present.
  static bool get isConfigured => endpoint.isNotEmpty && apiKey.isNotEmpty;

  /// Seconds to wait for a generation before giving up.
  static const int timeoutSeconds = 60;
}
