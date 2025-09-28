import 'dart:async';
import 'dart:convert';

import 'package:buddy/models/note_model.dart';
import 'package:buddy/providers/notes_provider.dart';
import 'package:buddy/widgets/custom_tool_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditNotesScreen extends ConsumerStatefulWidget {
  final Note? existingNote;

  const EditNotesScreen({super.key, required this.existingNote});

  @override
  ConsumerState<EditNotesScreen> createState() => _EditNotesScreenState();
}

class _EditNotesScreenState extends ConsumerState<EditNotesScreen>
    with WidgetsBindingObserver {
  QuillController _controller = QuillController.basic();
  final _focusNode = FocusNode();
  late String _initialContentJson;
  late String _initialPlainText;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();
    if (widget.existingNote != null) {
      // load existing note from JSON
      final decoded = jsonDecode((widget.existingNote!.contentJson));
      _controller = QuillController(
        document: Document.fromJson(decoded as List),
        selection: const TextSelection.collapsed(offset: 0),
      );
      // save snapshot
      _initialContentJson = widget.existingNote!.contentJson;
      _initialPlainText = widget.existingNote!.content;
    } else {
      // new empty note
      _controller = QuillController.basic();

      // new note starts empty
      _initialPlainText = "";
      _initialContentJson = "";
    }
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  //save notes in case app force closes

  // save note
  Future<void> _saveNote() async {
    final plainText = _controller.document.toPlainText().trim();
    final contentJson = jsonEncode(_controller.document.toDelta().toJson());

    // ignore if empty
    if (plainText.isEmpty) {
      return;
    }
    // ignore if no changes were made
    if (plainText == _initialPlainText && contentJson == _initialContentJson) {
      return;
    }
    if (widget.existingNote != null) {
      // update existing note
      ref
          .read(notesProvider.notifier)
          .updateNote(
            id: widget.existingNote!.id,
            content: plainText,
            contentJson: contentJson,
          );
    } else {
      ref
          .read(notesProvider.notifier)
          .addNote(content: plainText, contentJson: contentJson);
    }

    // refresh snapshot after successful save
    _initialPlainText = plainText;
    _initialContentJson = contentJson;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveNote();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _controller.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) return;
        _saveNote();
      },
      child: Scaffold(
        appBar: AppBar(),
        body: _content(_controller, _focusNode),
      ),
    );
  }
}

// Scaffold content
Widget _content(QuillController controller, FocusNode focusNode) {
  return Stack(
    children: [
      Positioned.fill(
        child: QuillEditor(
          config: QuillEditorConfig(
            scrollable: true,
            autoFocus: false,
            padding: EdgeInsets.fromLTRB(25.r, 25.r, 25.r, 80.r),
            expands: true,
          ),
          controller: controller,
          scrollController: ScrollController(),
          focusNode: focusNode,
        ),
      ),
      if (focusNode.hasFocus)
        Positioned(
          right: 0.0,
          left: 0.0,
          bottom: 0,

          child: CustomToolBar(controller: controller),
        ),
    ],
  );
}
