abstract final class AppConfig {
  static const name = 'FOR THE RECORD';
  static const subtitle = 'For the record, this is why I did it.';
  static const apiUrl = String.fromEnvironment('API_URL');
  static const identityUri = String.fromEnvironment(
    'IDENTITY_URI',
    defaultValue: 'https://workroom-seeker-6984.web.app',
  );
  static const directWallet = bool.fromEnvironment(
    'DIRECT_WALLET',
    defaultValue: true,
  );
  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const firebaseSenderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const configured =
      apiUrl != '' &&
      identityUri != '' &&
      firebaseApiKey != '' &&
      firebaseAppId != '' &&
      firebaseProjectId != '' &&
      firebaseSenderId != '';
  static const skrMint = 'SKRbvo6Gf7GondiT3BbTfuRDPqLWei4j2Qy2NPGZhW3';
}
