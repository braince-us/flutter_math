import '../../ast/font_metrics.dart';
import '../../ast/size.dart';
import '../../ast/types.dart';
import 'font_metrics_data.dart';
import 'unicode_scripts.dart';

/// This file contains metrics regarding fonts and individual symbols. The sigma
/// and xi variables, as well as the metricMap map contain data extracted from
/// TeX, TeX font metrics, and the TTF files. These data are then exposed via
/// the `metrics` variable and the getCharacterMetrics function.

// In TeX, there are actually three sets of dimensions, one for each of
// textstyle (size index 5 and higher: >=9pt), scriptstyle (size index 3 and 4:
// 7-8pt), and scriptscriptstyle (size index 1 and 2: 5-6pt).  These are
// provided in the the arrays below, in that order.
//
// The font metrics are stored in fonts cmsy10, cmsy7, and cmsy5 respsectively.
// This was determined by running the following script:
//
//     latex -interaction=nonstopmode \
//     '\documentclass{article}\usepackage{amsmath}\begin{document}' \
//     '$a$ \expandafter\show\the\textfont2' \
//     '\expandafter\show\the\scriptfont2' \
//     '\expandafter\show\the\scriptscriptfont2' \
//     '\stop'
//
// The metrics themselves were retreived using the following commands:
//
//     tftopl cmsy10
//     tftopl cmsy7
//     tftopl cmsy5
//
// The output of each of these commands is quite lengthy.  The only part we
// care about is the FONTDIMEN section. Each value is measured in EMs.
const sigmasAndXis = {
  'slant': [0.250, 0.250, 0.250], // sigma1
  'space': [0.000, 0.000, 0.000], // sigma2
  'stretch': [0.000, 0.000, 0.000], // sigma3
  'shrink': [0.000, 0.000, 0.000], // sigma4
  'xHeight': [0.431, 0.431, 0.431], // sigma5
  'quad': [1.000, 1.171, 1.472], // sigma6
  'extraSpace': [0.000, 0.000, 0.000], // sigma7
  'num1': [0.677, 0.732, 0.925], // sigma8
  'num2': [0.394, 0.384, 0.387], // sigma9
  'num3': [0.444, 0.471, 0.504], // sigma10
  'denom1': [0.686, 0.752, 1.025], // sigma11
  'denom2': [0.345, 0.344, 0.532], // sigma12
  'sup1': [0.413, 0.503, 0.504], // sigma13
  'sup2': [0.363, 0.431, 0.404], // sigma14
  'sup3': [0.289, 0.286, 0.294], // sigma15
  'sub1': [0.150, 0.143, 0.200], // sigma16
  'sub2': [0.247, 0.286, 0.400], // sigma17
  'supDrop': [0.386, 0.353, 0.494], // sigma18
  'subDrop': [0.050, 0.071, 0.100], // sigma19
  'delim1': [2.390, 1.700, 1.980], // sigma20
  'delim2': [1.010, 1.157, 1.420], // sigma21
  'axisHeight': [0.250, 0.250, 0.250], // sigma22

  // These font metrics are extracted from TeX by using tftopl on cmex10.tfm;
  // they correspond to the font parameters of the extension fonts (family 3).
  // See the TeXbook, page 441. In AMSTeX, the extension fonts scale; to
  // match cmex7, we'd use cmex7.tfm values for script and scriptscript
  // values.
  'defaultRuleThickness': [0.04, 0.049, 0.049], // xi8; cmex7: 0.049
  'bigOpSpacing1': [0.111, 0.111, 0.111], // xi9
  'bigOpSpacing2': [0.166, 0.166, 0.166], // xi10
  'bigOpSpacing3': [0.2, 0.2, 0.2], // xi11
  'bigOpSpacing4': [0.6, 0.611, 0.611], // xi12; cmex7: 0.611
  'bigOpSpacing5': [0.1, 0.143, 0.143], // xi13; cmex7: 0.143

  // The \sqrt rule width is taken from the height of the surd character.
  // Since we use the same font at all sizes, this thickness doesn't scale.
  'sqrtRuleThickness': [0.04, 0.04, 0.04],

  // This value determines how large a pt is, for metrics which are defined
  // in terms of pts.
  // This value is also used in katex.less; if you change it make sure the
  // values match.
  'ptPerEm': [10.0, 10.0, 10.0],

  // The space between adjacent `|` columns in an array definition. From
  // `\showthe\doublerulesep` in LaTeX. Equals 2.0 / ptPerEm.
  'doubleRuleSep': [0.2, 0.2, 0.2],

  // The width of separator lines in {array} environments. From
  // `\showthe\arrayrulewidth` in LaTeX. Equals 0.4 / ptPerEm.
  'arrayRuleWidth': [0.04, 0.04, 0.04],

  // Two values from LaTeX source2e:
  'fboxsep': [0.3, 0.3, 0.3], //        3 pt / ptPerEm
  'fboxrule': [0.04, 0.04, 0.04], // 0.4 pt / ptPerEm
};

final textFontMetrics = FontMetrics.fromMap(
    sigmasAndXis.map((key, value) => MapEntry(key, value[0])))!;

final scriptFontMetrics = FontMetrics.fromMap(
    sigmasAndXis.map((key, value) => MapEntry(key, value[1])))!;

final scriptscriptFontMetrics = FontMetrics.fromMap(
    sigmasAndXis.map((key, value) => MapEntry(key, value[2])))!;

const extraCharacterMap = {
  // Latin-1
  'Å': 'A',
  'Ç': 'C',
  'Ð': 'D',
  'Þ': 'o',
  'å': 'a',
  'ç': 'c',
  'ð': 'd',
  'þ': 'o',

  // Cyrillic
  'А': 'A',
  'Б': 'B',
  'В': 'B',
  'Г': 'F',
  'Д': 'A',
  'Е': 'E',
  'Ж': 'K',
  'З': '3',
  'И': 'N',
  'Й': 'N',
  'К': 'K',
  'Л': 'N',
  'М': 'M',
  'Н': 'H',
  'О': 'O',
  'П': 'N',
  'Р': 'P',
  'С': 'C',
  'Т': 'T',
  'У': 'y',
  'Ф': 'O',
  'Х': 'X',
  'Ц': 'U',
  'Ч': 'h',
  'Ш': 'W',
  'Щ': 'W',
  'Ъ': 'B',
  'Ы': 'X',
  'Ь': 'B',
  'Э': '3',
  'Ю': 'X',
  'Я': 'R',
  'а': 'a',
  'б': 'b',
  'в': 'a',
  'г': 'r',
  'д': 'y',
  'е': 'e',
  'ж': 'm',
  'з': 'e',
  'и': 'n',
  'й': 'n',
  'к': 'n',
  'л': 'n',
  'м': 'm',
  'н': 'n',
  'о': 'o',
  'п': 'n',
  'р': 'p',
  'с': 'c',
  'т': 'o',
  'у': 'y',
  'ф': 'b',
  'х': 'x',
  'ц': 'n',
  'ч': 'n',
  'ш': 'w',
  'щ': 'w',
  'ъ': 'a',
  'ы': 'm',
  'ь': 'a',
  'э': 'e',
  'ю': 'm',
  'я': 'r',
};

class CharacterMetrics {
  final double depth;
  final double height;
  final double italic;
  final double skew;
  final double width;
  const CharacterMetrics(
    this.depth,
    this.height,
    this.italic,
    this.skew,
    this.width,
  );
}

final Map<String, Map<int, CharacterMetrics>> metricsMap = fontMetricsData;

CharacterMetrics? getCharacterMetrics(
    {required String character, required String fontName, required Mode mode}) {
  final metricsMapFont = metricsMap[fontName];
  if (metricsMapFont == null) {
    throw Exception('Font metrics not found for font: $fontName.');
  }

  final ch = character.codeUnitAt(0);
  if (metricsMapFont.containsKey(ch)) {
    return metricsMapFont[ch];
  }

  final extraCh = extraCharacterMap[character[0]]?.codeUnitAt(0);
  if (extraCh != null) {
    return metricsMapFont[ch];
  }
  if (mode == Mode.text && supportedCodepoint(ch)) {
    // We don't typically have font metrics for Asian scripts.
    // But since we support them in text mode, we need to return
    // some sort of metrics.
    // So if the character is in a script we support but we
    // don't have metrics for it, just use the metrics for
    // the Latin capital letter M. This is close enough because
    // we (currently) only care about the height of the glpyh
    // not its width.
    return metricsMapFont[77]; // 77 is the charcode for 'M'
  }
  return null;
}

FontMetrics getGlobalMetrics(MathSize size) {
  switch (size) {
    case MathSize.tiny:
    case MathSize.size2:
      return scriptscriptFontMetrics;
    case MathSize.scriptsize:
    case MathSize.footnotesize:
      return scriptFontMetrics;
    case MathSize.small:
    case MathSize.normalsize:
    case MathSize.large:
    case MathSize.Large:
    case MathSize.LARGE:
    case MathSize.huge:
    case MathSize.HUGE:
      return textFontMetrics;
  }
}
