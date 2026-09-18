const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8090/api',
);

const inactivityTimeout = Duration(minutes: 3);
const inactivityWarning = Duration(seconds: 30);
const maxSessionDuration = Duration(hours: 8);
