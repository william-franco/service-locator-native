import 'package:flutter/material.dart';

export 'stream_state_management.dart';

import 'stream_state_management.dart';

abstract interface class Disposable {
  void dispose();
}

abstract class ProviderBase<T> {
  ProviderBase(this._factory);

  final T Function(Ref ref) _factory;

  S call<S extends T>() => _globalContainer.read(this) as S;
}

class Provider<T> extends ProviderBase<T> {
  Provider(super.create);

  AutoDisposeProvider<T> get autoDispose => AutoDisposeProvider<T>(_factory);
}

class AutoDisposeProvider<T> extends ProviderBase<T> {
  AutoDisposeProvider(super.create);
}

class Ref {
  Ref(this._container);

  final ProviderContainer _container;

  T read<T>(ProviderBase<T> provider) => _container.read(provider);
}

class ProviderContainer {
  final _cache = <ProviderBase<Object?>, Object?>{};

  T read<T>(ProviderBase<T> provider) {
    final cached = _cache[provider];
    if (cached != null) {
      return cached as T;
    }

    final instance = provider._factory(Ref(this));
    _cache[provider] = instance;
    return instance;
  }

  void dispose() {
    for (final entry in _cache.entries) {
      if (entry.key is! AutoDisposeProvider<Object?>) continue;

      final value = entry.value;
      if (value is StreamStateManagement) {
        value.dispose();
      } else if (value is Disposable) {
        value.dispose();
      }
    }
    _cache.clear();
  }
}

ProviderContainer _globalContainer = ProviderContainer();

class ProviderScope extends StatefulWidget {
  const ProviderScope({super.key, required this.child});

  final Widget child;

  @override
  State<ProviderScope> createState() => _ProviderScopeState();
}

class _ProviderScopeState extends State<ProviderScope> {
  @override
  void initState() {
    super.initState();
    _globalContainer = ProviderContainer();
  }

  @override
  void dispose() {
    _globalContainer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
