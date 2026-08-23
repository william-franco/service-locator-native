import 'dart:async';

import 'package:flutter/material.dart';

abstract class StreamStateManagement<T> {
  late T _state;
  late final StreamController<T> _controller;

  StreamStateManagement() {
    _controller = StreamController<T>.broadcast();
    _state = build();
  }

  @protected
  T build();

  T get state => _state;

  Stream<T> get stream => _controller.stream;

  @protected
  void emitState(T newState) {
    if (_state == newState) return;
    if (_controller.isClosed) return;
    _state = newState;
    _controller.add(_state);
  }

  @mustCallSuper
  void dispose() {
    _controller.close();
  }

  @override
  String toString() => 'StreamStateManagement<$T>(state: $_state)';
}

typedef StreamStateBuilder<S> = Widget Function(BuildContext context, S state);

class StreamBuilderWidget<V extends StreamStateManagement<S>, S>
    extends StatelessWidget {
  final V Function() viewModel;
  final StreamStateBuilder<S> builder;

  const StreamBuilderWidget({
    super.key,
    required this.viewModel,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final vm = viewModel();
    return StreamBuilder<S>(
      initialData: vm.state,
      stream: vm.stream,
      builder: (context, snapshot) => builder(context, snapshot.requireData),
    );
  }
}

typedef StreamStateListener<S> = void Function(BuildContext context, S state);

class StreamListenerWidget<V extends StreamStateManagement<S>, S>
    extends StatefulWidget {
  final V Function() viewModel;
  final StreamStateListener<S> listener;
  final Widget child;

  const StreamListenerWidget({
    super.key,
    required this.viewModel,
    required this.listener,
    required this.child,
  });

  @override
  State<StreamListenerWidget<V, S>> createState() =>
      _StreamListenerWidgetState<V, S>();
}

class _StreamListenerWidgetState<V extends StreamStateManagement<S>, S>
    extends State<StreamListenerWidget<V, S>> {
  late final V _viewModel;
  late final StreamSubscription<S> _subscription;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel();
    _subscription = _viewModel.stream.listen((state) {
      if (mounted) widget.listener(context, state);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class StreamConsumerWidget<V extends StreamStateManagement<S>, S>
    extends StatefulWidget {
  final V Function() viewModel;
  final StreamStateListener<S> listener;
  final StreamStateBuilder<S> builder;

  const StreamConsumerWidget({
    super.key,
    required this.viewModel,
    required this.listener,
    required this.builder,
  });

  @override
  State<StreamConsumerWidget<V, S>> createState() =>
      _StreamConsumerWidgetState<V, S>();
}

class _StreamConsumerWidgetState<V extends StreamStateManagement<S>, S>
    extends State<StreamConsumerWidget<V, S>> {
  late final V _viewModel;
  late final StreamSubscription<S> _subscription;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel();
    _subscription = _viewModel.stream.listen((state) {
      if (mounted) widget.listener(context, state);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilderWidget<V, S>(
      viewModel: () => _viewModel,
      builder: widget.builder,
    );
  }
}
