part of 'signup_bloc.dart';

abstract class SignupEvent {}

class signupSubmitted extends SignupEvent {
  final String email;
  final String password;
  final String confirmpassword;
  final String name;
  signupSubmitted({
    required this.email,
    required this.password,
    required this.confirmpassword,
    required this.name,
  });
}
