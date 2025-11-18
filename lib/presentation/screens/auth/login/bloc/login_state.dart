part of 'login_bloc.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final String role;

  const LoginSuccess({required this.role});

  @override
  List<Object?> get props => [role];
}

class LoginFailed extends LoginState {
  final String message;

  const LoginFailed(this.message);

  @override
  List<Object?> get props => [message];
}
