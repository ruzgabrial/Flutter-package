part of '../sign_in.dart';

final signInPhoneVerificationControllerProvider =
    StateNotifierProvider.autoDispose<SignInPhoneVerificationController,
        SignInPhoneVerificationState>((ref) {
  final phoneNumber = ref.watch(signInPhoneControllerProvider.select(
    (state) => state.phoneNumber,
  ));
  final verificationId = ref.watch(signInPhoneControllerProvider.select(
    (state) => state.verificationId,
  ));

  if (phoneNumber == null || verificationId == null) {
    throw UnimplementedError();
  }

  final authService = ref.watch(authServiceProvider);
  final localizations = ref.watch(signInLocalizationsProvider);

  return SignInPhoneVerificationController(
    phoneNumber,
    verificationId,
    authService,
    localizations,
  );
}, dependencies: [
  authServiceProvider,
  signInLocalizationsProvider,
]);

@freezed
class SignInPhoneVerificationEvent with _$SignInPhoneVerificationEvent {
  const factory SignInPhoneVerificationEvent.resendCode() = _ResendCode;
  const factory SignInPhoneVerificationEvent.codeChanged(String input) =
      _CodeChanged;
  const factory SignInPhoneVerificationEvent.verifyCode() = _VerifyCode;
}

@freezed
class SignInPhoneVerificationState with _$SignInPhoneVerificationState {
  const factory SignInPhoneVerificationState({
    @Default(delayBeforeUserCanRequestNewCode) int countdown,
    required Map<String, dynamic> phoneNumber,
    required String verificationId,
    @Default("") String verificationCode,
    @Default(false) bool canSubmit,
    @Default(false) bool isLoading,
    @Default(false) bool isSuccess,
    String? errorText,
  }) = _SignInPhoneVerificationState;
}

/// An object which controls the state of the verification form.
///
/// It uses a [StateNotifier] to return a [SubmitState] and also
/// do more much stuff such as parsing the phone number and submit the form.
///
/// The core of the functions are in the [AuthService] class because
/// these functions are also used in the member section of the app.
class SignInPhoneVerificationController
    extends StateNotifier<SignInPhoneVerificationState> {
  SignInPhoneVerificationController(
    Map<String, dynamic> phoneNumber,
    String verificationId,
    this._service,
    this._localizations,
  ) : super(SignInPhoneVerificationState(
          verificationId: verificationId,
          phoneNumber: phoneNumber,
        )) {
    _startTimer();
  }

  final FirebaseAuthService _service;
  final SignInLocalizations _localizations;

  String get formattedPhoneNumber =>
      state.phoneNumber['national'].replaceAll(" ", "\u00A0");

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    state = state.copyWith(countdown: delayBeforeUserCanRequestNewCode);
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (state.countdown == 0) {
          timer.cancel();
        } else {
          state = state.copyWith(countdown: state.countdown - 1);
        }
      },
    );
  }

  void handleEvent(SignInPhoneVerificationEvent event) {
    event.when(
      codeChanged: (input) {
        state = state.copyWith(
          verificationCode: input,
          canSubmit: input.length == 6,
        );
      },
      resendCode: _resendCode,
      verifyCode: _verifyCode,
    );
  }

  Future<void> _resendCode() async {
    state = state.copyWith(isLoading: true);

    try {
      _service.verifyPhone(state.phoneNumber['e164'], (verificationId) {
        state = state.copyWith(
          isLoading: false,
          verificationId: verificationId,
        );
      });
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorText: e.message!,
      );
    }
  }

  Future<void> _verifyCode() async {
    if (!state.canSubmit) return;
    state = state.copyWith(isLoading: true);

    try {
      _service.verifyCode(state.verificationId, state.verificationCode, () {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
        );
      });
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorText: e.description(_localizations),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorText: e.toString(),
      );
    }
  }
}
