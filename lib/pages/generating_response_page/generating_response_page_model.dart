import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'generating_response_page_widget.dart' show GeneratingResponsePageWidget;
import 'package:flutter/material.dart';

class GeneratingResponsePageModel
    extends FlutterFlowModel<GeneratingResponsePageWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
