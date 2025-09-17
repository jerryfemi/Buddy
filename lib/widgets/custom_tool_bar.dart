import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomToolBar extends StatelessWidget {
  final QuillController controller;

  const CustomToolBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 0.h),
        child: Container(
          decoration: BoxDecoration(
            // borderRadius: BorderRadius.circular(18.r),
            color: Theme.of(context).colorScheme.secondary,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,padding: EdgeInsets.all(5.r),
            child: QuillSimpleToolbar(
              controller: controller,
              config: QuillSimpleToolbarConfig(
                showBackgroundColorButton: false,
                showClipboardPaste: false,
                showCodeBlock: false,
                showColorButton: false,
                showFontFamily: false,
                showFontSize: false,
                showHeaderStyle: false,
                showIndent: false,
                showClearFormat: false,
                showListCheck: false,
                showQuote: false,
                showLink: false,
                showUnderLineButton: false,
                showSubscript: false,
                showSuperscript: false,
                showListBullets: false,
                showListNumbers: false,
                showInlineCode: false,
                showDividers: false,
                showStrikeThrough: false,
                showAlignmentButtons: true,
                showJustifyAlignment: false,showSearchButton: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
