import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:tuple/tuple.dart';

import '../../ast/options.dart';
import '../../ast/size.dart';
import '../../ast/style.dart';
import '../../ast/syntax_tree.dart';
import '../../utils/iterable_extensions.dart';
import 'custom_layout.dart';

/// This should be the perfect use case for [CustomMultiChildLayout] and
/// [MultiChildLayoutDelegate]. However, they don't support baseline
/// functionalities. So we have to start from [MultiChildRenderObjectWidget].
///
/// This should also be a great showcase for [LayoutId], but the generic
/// parameter prevents us to use or extend from [LayoutId].
///
/// This should also be a great showcase for [MultiChildLayoutParentData],
/// but the lack of generic ([Object] type) is undesirable.

enum ScriptPos {
  base,
  sub,
  sup,
  presub,
  presup,
}

class Multiscripts extends StatelessWidget {
  const Multiscripts({
    super.key,
    this.alignPostscripts = false,
    required this.isBaseCharacterBox,
    required this.baseResult,
    this.subResult,
    this.supResult,
    this.presubResult,
    this.presupResult,
  });

  final bool alignPostscripts;
  final bool isBaseCharacterBox;

  final BuildResult baseResult;
  final BuildResult? subResult;
  final BuildResult? supResult;
  final BuildResult? presubResult;
  final BuildResult? presupResult;

  @override
  Widget build(BuildContext context) => CustomLayout(
        delegate: MultiscriptsLayoutDelegate(
          alignPostscripts: alignPostscripts,
          italic: baseResult.italic,
          isBaseCharacterBox: isBaseCharacterBox,
          baseOptions: baseResult.options,
          subOptions: subResult?.options,
          supOptions: supResult?.options,
          presubOptions: presubResult?.options,
          presupOptions: presupResult?.options,
        ),
        children: <Widget>[
          CustomLayoutId(
            id: ScriptPos.base,
            child: baseResult.widget,
          ),
          if (subResult != null)
            CustomLayoutId(
              id: ScriptPos.sub,
              child: subResult!.widget,
            ),
          if (supResult != null)
            CustomLayoutId(
              id: ScriptPos.sup,
              child: supResult!.widget,
            ),
          if (presubResult != null)
            CustomLayoutId(
              id: ScriptPos.presub,
              child: presubResult!.widget,
            ),
          if (presupResult != null)
            CustomLayoutId(
              id: ScriptPos.presup,
              child: presupResult!.widget,
            ),
        ],
      );
}

// Superscript and subscripts are handled in the TeXbook on page
// 445-446, rules 18(a-f).
class MultiscriptsLayoutDelegate extends IntrinsicLayoutDelegate<ScriptPos> {
  final bool alignPostscripts;
  final double italic;

  final bool isBaseCharacterBox;
  final MathOptions baseOptions;
  final MathOptions? subOptions;
  final MathOptions? supOptions;
  final MathOptions? presubOptions;
  final MathOptions? presupOptions;

  MultiscriptsLayoutDelegate({
    required this.alignPostscripts,
    required this.italic,
    required this.isBaseCharacterBox,
    required this.baseOptions,
    required this.subOptions,
    required this.supOptions,
    required this.presubOptions,
    required this.presupOptions,
  });

  var baselineDistance = 0.0;

  @override
  double computeDistanceToActualBaseline(
          TextBaseline baseline, Map<ScriptPos, RenderBox> childrenTable) =>
      baselineDistance;
  // // This will trigger Flutter assertion error
  // nPlus(
  //   childrenTable[ScriptPos.base].offset.dy,
  //   childrenTable[ScriptPos.base]
  //       .getDistanceToBaseline(baseline, onlyReal: true),
  // );

  @override
  AxisConfiguration<ScriptPos> performHorizontalIntrinsicLayout({
    required Map<ScriptPos, double> childrenWidths,
    bool isComputingIntrinsics = false,
  }) {
    final baseSize = childrenWidths[ScriptPos.base]!;
    final subSize = childrenWidths[ScriptPos.sub];
    final supSize = childrenWidths[ScriptPos.sup];
    final presubSize = childrenWidths[ScriptPos.presub];
    final presupSize = childrenWidths[ScriptPos.presup];

    final scriptSpace = 0.5.pt.toLpUnder(baseOptions);

    final extendedSubSize = subSize != null ? subSize + scriptSpace : 0.0;
    final extendedSupSize = supSize != null ? supSize + scriptSpace : 0.0;
    final extendedPresubSize =
        presubSize != null ? presubSize + scriptSpace : 0.0;
    final extendedPresupSize =
        presupSize != null ? presupSize + scriptSpace : 0.0;

    final postscriptWidth = math.max(
      extendedSupSize,
      -(alignPostscripts ? 0.0 : italic) + extendedSubSize,
    );
    final prescriptWidth = math.max(extendedPresubSize, extendedPresupSize);

    final fullSize = postscriptWidth + prescriptWidth + baseSize;

    return AxisConfiguration(
      size: fullSize,
      offsetTable: {
        ScriptPos.base: prescriptWidth,
        ScriptPos.sub:
            prescriptWidth + baseSize - (alignPostscripts ? 0.0 : italic),
        ScriptPos.sup: prescriptWidth + baseSize,
        if (presubSize != null) ScriptPos.presub: prescriptWidth - presubSize,
        if (presupSize != null) ScriptPos.presup: prescriptWidth - presupSize,
      },
    );
  }

  @override
  AxisConfiguration<ScriptPos> performVerticalIntrinsicLayout({
    required Map<ScriptPos, double> childrenHeights,
    required Map<ScriptPos, double> childrenBaselines,
    bool isComputingIntrinsics = false,
  }) {
    final baseSize = childrenHeights[ScriptPos.base]!;
    final subSize = childrenHeights[ScriptPos.sub];
    final supSize = childrenHeights[ScriptPos.sup];
    final presubSize = childrenHeights[ScriptPos.presub];
    final presupSize = childrenHeights[ScriptPos.presup];

    final baseHeight = childrenBaselines[ScriptPos.base]!;
    final subHeight = childrenBaselines[ScriptPos.sub];
    final supHeight = childrenBaselines[ScriptPos.sup];
    final presubHeight = childrenBaselines[ScriptPos.presub];
    final presupHeight = childrenBaselines[ScriptPos.presup];

    final postscriptRes = calculateUV(
      base: ScriptUvConf(baseSize, baseHeight, baseOptions),
      sub: subSize != null
          ? ScriptUvConf(subSize, subHeight!, subOptions!)
          : null,
      sup: supSize != null
          ? ScriptUvConf(supSize, supHeight!, supOptions!)
          : null,
      isBaseCharacterBox: isBaseCharacterBox,
    );

    final prescriptRes = calculateUV(
      base: ScriptUvConf(baseSize, baseHeight, baseOptions),
      sub: presubSize != null
          ? ScriptUvConf(presubSize, presubHeight!, presubOptions!)
          : null,
      sup: presupSize != null
          ? ScriptUvConf(presupSize, presupHeight!, presupOptions!)
          : null,
      isBaseCharacterBox: isBaseCharacterBox,
    );

    final subShift = postscriptRes.item2;
    final supShift = postscriptRes.item1;
    final presubShift = prescriptRes.item2;
    final presupShift = prescriptRes.item1;

    // Rule 18f
    final height = [
      baseHeight,
      if (subHeight != null) subHeight - subShift,
      if (supHeight != null) supHeight + supShift,
      if (presubHeight != null) presubHeight - presubShift,
      if (presupHeight != null) presupHeight + presupShift,
    ].max;

    final depth = [
      baseSize - baseHeight,
      if (subHeight != null) subSize! - subHeight + subShift,
      if (supHeight != null) supSize! - supHeight - supShift,
      if (presubHeight != null) presubSize! - presubHeight + presubShift,
      if (presupHeight != null) presupSize! - presupHeight - presupShift,
    ].max;

    if (!isComputingIntrinsics) {
      baselineDistance = height;
    }

    return AxisConfiguration(
      size: height + depth,
      offsetTable: {
        ScriptPos.base: height - baseHeight,
        if (subHeight != null) ScriptPos.sub: height + subShift - subHeight,
        if (supHeight != null) ScriptPos.sup: height - supShift - supHeight,
        if (presubHeight != null)
          ScriptPos.presub: height + presubShift - presubHeight,
        if (presupHeight != null)
          ScriptPos.presup: height - presupShift - presupHeight,
      },
    );
  }
}

class ScriptUvConf {
  final double fullHeight;
  final double baseline;
  final MathOptions options;

  const ScriptUvConf(this.fullHeight, this.baseline, this.options);
}

Tuple2<double, double> calculateUV({
  required ScriptUvConf base,
  ScriptUvConf? sub,
  ScriptUvConf? sup,
  required bool isBaseCharacterBox,
}) {
  final metrics = base.options.fontMetrics;
  final baseOptions = base.options;

  // TexBook Rule 18a
  final h = base.baseline;
  final d = base.fullHeight - h;
  var u = 0.0;
  var v = 0.0;
  if (sub != null) {
    final r = sub.options.fontMetrics.subDrop.cssEm.toLpUnder(sub.options);
    v = isBaseCharacterBox ? 0 : d + r;
  }
  if (sup != null) {
    final q = sup.options.fontMetrics.supDrop.cssEm.toLpUnder(sup.options);
    u = isBaseCharacterBox ? 0 : h - q;
  }

  if (sup == null && sub != null) {
    // Rule 18b
    final hx = sub.baseline;
    v = math.max(
      v,
      math.max(
        metrics.sub1.cssEm.toLpUnder(baseOptions),
        hx - 0.8 * metrics.xHeight.cssEm.toLpUnder(baseOptions),
      ),
    );
  } else if (sup != null) {
    // Rule 18c
    final dx = sup.fullHeight - sup.baseline;
    final p = (baseOptions.style == MathStyle.display
            ? metrics.sup1
            : (baseOptions.style.cramped ? metrics.sup3 : metrics.sup2))
        .cssEm
        .toLpUnder(baseOptions);

    u = math.max(
      u,
      math.max(
        p,
        dx + 0.25 * metrics.xHeight.cssEm.toLpUnder(baseOptions),
      ),
    );
    // Rule 18d
    if (sub != null) {
      v = math.max(v, metrics.sub2.cssEm.toLpUnder(baseOptions));
      // Rule 18e
      final theta = metrics.defaultRuleThickness.cssEm.toLpUnder(baseOptions);
      final hy = sub.baseline;
      if ((u - dx) - (hy - v) < 4 * theta) {
        v = 4 * theta - u + dx + hy;
        final psi =
            0.8 * metrics.xHeight.cssEm.toLpUnder(baseOptions) - (u - dx);
        if (psi > 0) {
          u += psi;
          v -= psi;
        }
      }
    }
  }
  return Tuple2(u, v);
}
