import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'signup_event.dart';
part 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  SignupBloc() : super(SignupInitial()) {
    on<signupSubmitted>(_onSignup);
  }

  final supabase = Supabase.instance.client;

  Future<void> _onSignup(
    signupSubmitted event,
    Emitter<SignupState> emit,
  ) async {
    emit(SignupLoading());

    // Validate passwords
    if (event.password != event.confirmpassword) {
      emit(SignupFailure("Passwords do not match"));
      return;
    }

    try {
      // Signup in Supabase Auth
      final response = await supabase.auth.signUp(
        email: event.email,
        password: event.password,
      );

      if (response.user == null) {
        emit(SignupFailure("Signup failed"));
        return;
      }

      // Insert user profile
      await supabase.from("profiles").insert({
        "id": response.user!.id,
        "name": event.name,
        "role": "user", // or admin manually in DB
      });

      emit(SignupSuccess());
    } catch (e) {
      emit(SignupFailure(e.toString()));
    }
  }
}
