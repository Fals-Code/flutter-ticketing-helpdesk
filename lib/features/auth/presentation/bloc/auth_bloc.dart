import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/usecases/usecase.dart';
import 'package:uts/features/auth/domain/entities/user_entity.dart';
import 'package:uts/features/auth/domain/usecases/auth_usecases.dart';
import 'package:uts/features/auth/domain/usecases/update_avatar_usecase.dart';
import 'package:uts/features/auth/domain/usecases/update_password_usecase.dart';
import 'package:uts/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:uts/features/auth/presentation/bloc/auth_event.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';

part 'auth_bloc_access_handlers.dart';
part 'auth_bloc_avatar_handler.dart';
part 'auth_bloc_forgot_password_handler.dart';
part 'auth_bloc_password_handler.dart';
part 'auth_bloc_profile_handler.dart';
part 'auth_bloc_registration.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final UpdatePasswordUseCase updatePasswordUseCase;
  final UpdateAvatarUseCase updateAvatarUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final sup.SupabaseClient supabaseClient;

  StreamSubscription<dynamic>? _authSubscription;
  bool _signOutInProgress = false;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.resetPasswordUseCase,
    required this.updatePasswordUseCase,
    required this.updateAvatarUseCase,
    required this.updateProfileUseCase,
    required this.supabaseClient,
  }) : super(const AuthState()) {
    _registerAuthHandlers(this);
    _startAuthListener(this);
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    await super.close();
  }
}
