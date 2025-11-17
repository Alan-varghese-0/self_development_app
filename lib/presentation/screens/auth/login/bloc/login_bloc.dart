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
      if (res.user != null) {
        emit(LoginSuccess());
      } else {
        emit(LoginFailed("INvalid email or password"));
      }
    } catch (e) {
      emit(LoginFailed(e.toString()));
    }
  }
}
