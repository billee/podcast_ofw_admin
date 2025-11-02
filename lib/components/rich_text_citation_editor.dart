import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class RichTextCitationEditor extends StatefulWidget {
  final String initialText;
  final Function(String) onTextChanged;
  final String label;
  final VoidCallback? onRemove;
  final bool showRemoveButton;

  const RichTextCitationEditor({
    Key? key,
    required this.initialText,
    required this.onTextChanged,
    required this.label,
    this.onRemove,
    this.showRemoveButton = false,
  }) : super(key: key);

  @override
  State<RichTextCitationEditor> createState() => _RichTextCitationEditorState();
}

class _RichTextCitationEditorState extends State<RichTextCitationEditor> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    if (widget.initialText.isNotEmpty) {
      try {
        // Try to parse as JSON (rich text format)
        final json = jsonDecode(widget.initialText);
        _controller = QuillController(
          document: Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // If not JSON, treat as plain text
        _controller = QuillController.basic();
        _controller.document.insert(0, widget.initialText);
      }
    } else {
      _controller = QuillController.basic();
    }

    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Convert document to JSON string for storage
    final json = jsonEncode(_controller.document.toDelta().toJson());
    widget.onTextChanged(json);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with label and remove button
            Row(
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (widget.showRemoveButton && widget.onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                    onPressed: widget.onRemove,
                    tooltip: 'Remove citation',
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Rich text toolbar
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: QuillSimpleToolbar(
                controller: _controller,
                config: const QuillSimpleToolbarConfig(
                  multiRowsDisplay: false,
                  showFontFamily: false,
                  showFontSize: false,
                  showBoldButton: true,
                  showItalicButton: true,
                  showUnderLineButton: true,
                  showStrikeThrough: false,
                  showInlineCode: true,
                  showColorButton: false,
                  showBackgroundColorButton: false,
                  showClearFormat: true,
                  showAlignmentButtons: false,
                  showLeftAlignment: false,
                  showCenterAlignment: false,
                  showRightAlignment: false,
                  showJustifyAlignment: false,
                  showHeaderStyle: false,
                  showListNumbers: true,
                  showListBullets: true,
                  showListCheck: false,
                  showCodeBlock: false,
                  showQuote: true,
                  showIndent: false,
                  showLink: true,
                  showUndo: true,
                  showRedo: true,
                ),
              ),
            ),

            // Rich text editor
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: QuillEditor.basic(
                controller: _controller,
                focusNode: _focusNode,
                config: const QuillEditorConfig(
                  padding: EdgeInsets.all(12),
                  placeholder: 'Enter citation text with formatting...',
                ),
              ),
            ),

            const SizedBox(height: 8),
            
            // Help text
            const Text(
              'Use the toolbar above to format your citation text. Bold, italic, lists, and links are supported.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to convert rich text JSON back to plain text for display
String richTextToPlainText(String richTextJson) {
  try {
    final json = jsonDecode(richTextJson);
    final document = Document.fromJson(json);
    return document.toPlainText();
  } catch (e) {
    return richTextJson; // Return as-is if not JSON
  }
}

// Helper function to convert rich text JSON to HTML for display
String richTextToHtml(String richTextJson) {
  try {
    final json = jsonDecode(richTextJson);
    final document = Document.fromJson(json);
    
    // Simple conversion to HTML (you can enhance this)
    String html = '';
    for (final operation in document.toDelta().toList()) {
      if (operation.data is String) {
        String text = operation.data as String;
        
        if (operation.attributes != null) {
          final attrs = operation.attributes!;
          if (attrs['bold'] == true) text = '<strong>$text</strong>';
          if (attrs['italic'] == true) text = '<em>$text</em>';
          if (attrs['underline'] == true) text = '<u>$text</u>';
          if (attrs['link'] != null) text = '<a href="${attrs['link']}">$text</a>';
        }
        
        html += text;
      }
    }
    
    return html;
  } catch (e) {
    return richTextJson; // Return as-is if not JSON
  }
}

// Widget to display rich text content (read-only)
class RichTextViewer extends StatelessWidget {
  final String richTextJson;
  final double? height;

  const RichTextViewer({
    Key? key,
    required this.richTextJson,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      final json = jsonDecode(richTextJson);
      final document = Document.fromJson(json);
      final controller = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );
      controller.readOnly = true;

      return Container(
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: QuillEditor.basic(
          controller: controller,
          config: QuillEditorConfig(
            padding: const EdgeInsets.all(12),
            scrollable: true,
            autoFocus: false,
            expands: false,
          ),
        ),
      );
    } catch (e) {
      // If not rich text JSON, display as plain text
      return Container(
        height: height,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          richTextJson.isNotEmpty ? richTextJson : 'Empty citation',
          style: TextStyle(
            fontSize: 12,
            color: richTextJson.isNotEmpty ? Colors.black87 : Colors.grey,
          ),
        ),
      );
    }
  }
}