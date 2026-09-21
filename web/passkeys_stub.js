// Stand-in for the passkeys_web JS SDK.
//
// supabase_flutter depends on `passkeys`, and its web plugin calls
// PasskeyAuthenticator.init() while the app boots. Without that global the
// whole web build dies before the first frame. Fade does not offer passkey
// sign-in, so rather than vendoring Corbado's bundle.js this defines the same
// surface with passkeys reported as unavailable. It is a local file, so it
// fits the CSP's script-src 'self'. If passkey login is ever added, replace
// this with the real bundle.
(function () {
  var unsupported = function () {
    return Promise.reject(new Error('Passkeys are not supported in Fade web.'));
  };
  window.PasskeyAuthenticator = {
    init: function () {},
    register: unsupported,
    login: unsupported,
    cancelCurrentAuthenticatorOperation: function () {},
    isUserVerifyingPlatformAuthenticatorAvailable: function () {
      return Promise.resolve(false);
    },
    isConditionalMediationAvailable: function () {
      return Promise.resolve(false);
    },
    hasPasskeySupport: function () {
      return false;
    },
  };
})();
