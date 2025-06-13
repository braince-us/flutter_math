import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class RemoveBaseline extends SingleChildRenderObjectWidget {
  const RemoveBaseline({
    super.key,
    required Widget super.child,
  });

  @override
  RenderRemoveBaseline createRenderObject(BuildContext context) =>
      RenderRemoveBaseline();
}

class RenderRemoveBaseline extends RenderProxyBox {
  RenderRemoveBaseline({RenderBox? child}) : super(child);

  @override
  // ignore: avoid_returning_null
  double? computeDistanceToActualBaseline(TextBaseline baseline) => null;
}
