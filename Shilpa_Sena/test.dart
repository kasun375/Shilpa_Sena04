import 'package:google_sign_in/google_sign_in.dart';
void main() async {
  await GoogleSignIn.instance.initialize();
  GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
  GoogleSignInAuthentication auth = account.authentication;
  print(auth.idToken);
}
