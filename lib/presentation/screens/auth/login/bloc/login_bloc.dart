import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final SupabaseClient supabase;

  LoginBloc({required this.supabase}) : super(LoginInitial()) {
    on<LoginSubmitted>(_loginUser);
  }

  Future<void> _loginUser(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());

    try {
      final res = await supabase.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );

      if (res.user == null) {
        emit(LoginFailed("Invalid email or password"));
        return;
      }

      final userId = res.user!.id;

      final profile = await supabase
          .from("profiles")
          .select("role")
          .eq("id", userId)
          .maybeSingle();

      if (profile == null || profile["role"] == null) {
        emit(LoginFailed("No role assigned"));
        return;
      }

      final role = profile["role"].toString().trim().toLowerCase();
      print("🟢 LOGIN BLOC → ROLE: $role");

      emit(LoginSuccess(role: role));
    } catch (e) {
      emit(LoginFailed(e.toString()));
    }
  }
}
