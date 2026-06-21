import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Fungsi untuk memunculkan pop-up Google dan login
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Memicu proses pemilihan akun Google bawaan HP
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // Kalau user batalin (tutup pop-up sebelum milih), hentikan proses
      if (googleUser == null) return null; 

      // 2. Minta kunci akses (token) dari Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Masukkan kunci itu ke gembok Firebase kita
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // 4. Kembalikan data user (nama, email, foto) yang berhasil login
      return userCredential.user;
      
    } catch (e) {
      print("Waduh, Error Google Sign-In: $e");
      return null;
    }
  }

  // Fungsi untuk Logout nanti
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
