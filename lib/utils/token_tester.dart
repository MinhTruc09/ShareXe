import '../services/auth_manager.dart';

class TokenTester {
  final AuthManager _authManager = AuthManager();
  
  // Test method for token parsing
  void testTokenParsing() {
    const testToken = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJraGFjaHZpcDFAZ21haWwuY29tIiwicm9sZSI6IlBBU1NFTkdFUiIsImlhdCI6MTc0NjU0MzIyNiwiZXhwIjoxNzQ2NTQ2ODI2fQ.HJcwfXH5RfX_slVGzvCM15W91OAjIU7cxOSBQ1XlNcA';
    
    final claims = _authManager.parseJwt(testToken);
    
    if (claims != null) {
      // Print the claims
      print('Token claims:');
      print('Subject (email): ${claims['sub']}');
      print('Role: ${claims['role']}');
      print('Issued at: ${DateTime.fromMillisecondsSinceEpoch(claims['iat'] * 1000)}');
      print('Expires at: ${DateTime.fromMillisecondsSinceEpoch(claims['exp'] * 1000)}');
      print('Is expired: ${_authManager.isTokenExpired(testToken)}');
    } else {
      print('Failed to parse token');
    }
  }
  
  // This could be called during app initialization for testing
  static void runTest() {
    final tester = TokenTester();
    tester.testTokenParsing();
  }
} 