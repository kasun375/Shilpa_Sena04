import 'dart:isolate';
void main() async {
  var uri = await Isolate.resolvePackageUri(Uri.parse('package:google_sign_in/google_sign_in.dart'));
  print(uri);
}
