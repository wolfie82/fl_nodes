import 'package:example/nodes.dart';

import 'package:fl_nodes/fl_nodes.dart';

void registerDataHandlers(FlNodeEditorController controller) {
  controller.project.registerDataHandler<Operator>(
    toJson: (data) => data.toString().split('.').last,
    fromJson: (json) => Operator.values.firstWhere(
      (e) => e.toString().split('.').last == json,
    ),
  );
}
