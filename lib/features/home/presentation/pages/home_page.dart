import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/injection/injection.dart';
import '../../domain/entities/todo.dart';
import '../bloc/home_todo_bloc.dart';
import '../bloc/home_todo_event.dart';
import '../bloc/home_todo_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<HomeTodoBloc>()..add(const HomeTodoStarted()),
      child: const _HomeTodoView(),
    );
  }
}

class _HomeTodoView extends StatefulWidget {
  const _HomeTodoView();

  @override
  State<_HomeTodoView> createState() => _HomeTodoViewState();
}

class _HomeTodoViewState extends State<_HomeTodoView> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleDraftChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleDraftChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleDraftChanged() {
    final bloc = context.read<HomeTodoBloc>();
    if (bloc.state.draft == _controller.text) {
      return;
    }
    bloc.add(HomeTodoDraftChanged(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<HomeTodoBloc, HomeTodoState>(
      listener: (context, state) {
        if (_controller.text == state.draft) {
          return;
        }

        _controller.value = TextEditingValue(
          text: state.draft,
          selection: TextSelection.collapsed(offset: state.draft.length),
        );
        if (state.draft.isEmpty) {
          _focusNode.requestFocus();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Semantics(
              identifier: 'home.todo.title',
              child: const Text('Todo List'),
            ),
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
          ),
          body: SafeArea(
            child: Semantics(
              identifier: 'home.todo.page',
              explicitChildNodes: true,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.sizeOf(context).width >= 600 ? 32 : 16,
                      16,
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TodoComposer(
                          controller: _controller,
                          focusNode: _focusNode,
                          canAdd: state.canSubmit,
                          onAdd: () {
                            context.read<HomeTodoBloc>().add(
                              const HomeTodoSubmitted(),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _TodoSummary(
                          totalCount: state.todos.length,
                          completedCount: state.completedCount,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: state.todos.isEmpty
                              ? const _TodoEmptyState()
                              : Semantics(
                                  identifier: 'home.todo.list',
                                  explicitChildNodes: true,
                                  child: ListView.separated(
                                    itemCount: state.todos.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final item = state.todos[index];
                                      return _TodoTile(
                                        item: item,
                                        index: index,
                                        onChanged: (completed) {
                                          context.read<HomeTodoBloc>().add(
                                            HomeTodoCompletionToggled(
                                              id: item.id,
                                              completed: completed,
                                            ),
                                          );
                                        },
                                        onDelete: () {
                                          context.read<HomeTodoBloc>().add(
                                            HomeTodoDeleted(item.id),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TodoComposer extends StatelessWidget {
  const _TodoComposer({
    required this.controller,
    required this.focusNode,
    required this.canAdd,
    required this.onAdd,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canAdd;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Semantics(
            identifier: 'home.todo.input',
            textField: true,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Task',
                hintText: 'Buy milk',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => onAdd(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          identifier: 'home.todo.add',
          button: true,
          child: IconButton.filled(
            onPressed: canAdd ? onAdd : null,
            tooltip: 'Add task',
            icon: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _TodoSummary extends StatelessWidget {
  const _TodoSummary({required this.totalCount, required this.completedCount});

  final int totalCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final activeCount = totalCount - completedCount;

    return Row(
      children: [
        Semantics(
          identifier: 'home.todo.active_count',
          child: Text(
            '$activeCount active',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const Spacer(),
        Semantics(
          identifier: 'home.todo.completed_count',
          child: Text(
            '$completedCount completed',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _TodoEmptyState extends StatelessWidget {
  const _TodoEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Semantics(
        identifier: 'home.todo.empty',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist, size: 48, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'No tasks yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({
    required this.item,
    required this.index,
    required this.onChanged,
    required this.onDelete,
  });

  final Todo item;
  final int index;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      identifier: 'home.todo.item.$index',
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
          color: item.completed
              ? colorScheme.secondaryContainer
              : colorScheme.surfaceContainerHighest,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Semantics(
                identifier: 'home.todo.checkbox.$index',
                checked: item.completed,
                child: Checkbox(
                  value: item.completed,
                  onChanged: (value) => onChanged(value ?? false),
                ),
              ),
              Expanded(
                child: Semantics(
                  identifier: 'home.todo.item.title.$index',
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      decoration: item.completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                identifier: 'home.todo.delete.$index',
                button: true,
                child: IconButton(
                  onPressed: onDelete,
                  tooltip: 'Delete task',
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
