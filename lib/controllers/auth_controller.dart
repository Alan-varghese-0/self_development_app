import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController {
  final supabase = Supabase.instance.client;

  Future<String?> signup(String email, String password) async {
    try {
      final responce = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (responce.user == null) {
        return "sign-up failed";
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final responce = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (responce.user == null) {
        return "login failed";
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  bool isLoggedin() {
    return supabase.auth.currentUser != null;
  }
}
