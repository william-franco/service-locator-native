import 'package:flutter/material.dart';
import 'package:service_locator_native/service_locator.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Service Locator Native',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const UserView(),
    );
  }
}

sealed class StatePattern<S, E extends Exception> {
  const StatePattern();
}

final class InitialState<S, E extends Exception> extends StatePattern<S, E> {
  const InitialState();
}

final class LoadingState<S, E extends Exception> extends StatePattern<S, E> {
  const LoadingState();
}

final class SuccessState<S, E extends Exception> extends StatePattern<S, E> {
  final S data;

  const SuccessState({required this.data});
}

final class ErrorState<S, E extends Exception> extends StatePattern<S, E> {
  final E error;

  const ErrorState({required this.error});
}

sealed class ResultPattern<S, E extends Exception> {
  const ResultPattern();

  T fold<T>({
    required T Function(S value) onSuccess,
    required T Function(E error) onError,
  }) {
    switch (this) {
      case SuccessResult(value: final v):
        return onSuccess(v);
      case ErrorResult(error: final e):
        return onError(e);
    }
  }
}

final class SuccessResult<S, E extends Exception> extends ResultPattern<S, E> {
  final S value;

  const SuccessResult({required this.value});
}

final class ErrorResult<S, E extends Exception> extends ResultPattern<S, E> {
  final E error;

  const ErrorResult({required this.error});
}

class UserException implements Exception {
  final String message;

  const UserException(this.message);

  @override
  String toString() => 'UserException: $message';
}

class UserModel {
  final String? name;

  const UserModel({this.name});
}

typedef UserResult = ResultPattern<UserModel, UserException>;

abstract interface class UserRepository {
  Future<UserResult> findOneUser();
}

class UserRepositoryImpl implements UserRepository {
  @override
  Future<UserResult> findOneUser() async {
    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      return const SuccessResult(value: UserModel(name: 'John Doe'));
    } catch (error) {
      return ErrorResult(error: UserException('An error occurred.'));
    }
  }
}

typedef UserState = StatePattern<UserModel, UserException>;

typedef _ViewModel = StreamStateManagement<UserState>;

abstract interface class UserViewModel extends _ViewModel {
  Future<void> getUserData();
}

class UserViewModelImpl extends _ViewModel implements UserViewModel {
  UserViewModelImpl({required this.userRepository});

  final UserRepository userRepository;

  @override
  UserState build() => const InitialState();

  @override
  Future<void> getUserData() async {
    _emit(const LoadingState());

    final result = await userRepository.findOneUser();
    final userState = result.fold<UserState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );

    _emit(userState);
  }

  void _emit(UserState newState) {
    emitState(newState);
    debugPrint('User state: $state');
  }
}

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(),
);

final userViewModelProvider = AutoDisposeProvider<UserViewModel>(
  (ref) => UserViewModelImpl(userRepository: ref.read(userRepositoryProvider)),
);

class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userViewModelProvider().getUserData();
    });
  }

  Future<void> _refresh() => userViewModelProvider().getUserData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Center(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: StreamBuilderWidget<UserViewModel, UserState>(
            viewModel: () => userViewModelProvider(),
            builder: (context, state) {
              return switch (state) {
                InitialState() => const SizedBox.shrink(),
                LoadingState() => const CircularProgressIndicator(),
                SuccessState(data: final user) => Text('User: ${user.name}'),
                ErrorState(error: final e) => Text('Error: ${e.message}'),
              };
            },
          ),
        ),
      ),
    );
  }
}
