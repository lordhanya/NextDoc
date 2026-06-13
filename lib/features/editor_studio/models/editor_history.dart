import 'dart:typed_data';

final class EditorState {
  final List<Uint8List> pages;
  final int currentPage;

  const EditorState({
    required this.pages,
    required this.currentPage,
  });
}

final class EditorHistory {
  final List<EditorState> _undoStack = [];
  final List<EditorState> _redoStack = [];
  static const int _maxHistory = 50;

  void pushState(EditorState state) {
    _undoStack.add(state);
    if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  EditorState? undo() {
    if (_undoStack.isEmpty) return null;
    final current = _undoStack.removeLast();
    _redoStack.add(current);
    return _undoStack.isEmpty ? null : _undoStack.last;
  }

  EditorState? redo() {
    if (_redoStack.isEmpty) return null;
    final state = _redoStack.removeLast();
    _undoStack.add(state);
    return state;
  }

  bool get canUndo => _undoStack.length > 1;
  bool get canRedo => _redoStack.isNotEmpty;

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
