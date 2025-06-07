from fontTools.ttLib import TTFont
from fontTools.pens.boundsPen import BoundsPen
import traceback
import argparse

def debug_font_structure(font_path):
    """Debug the font structure to understand the issue"""
    font = TTFont(font_path)

    head = font['head']
    hhea = font['hhea']
    hmtx = font['hmtx']
    cmap = font.getBestCmap()

    print(f"Font: {font_path}")
    print(f"Units per EM: {head.unitsPerEm}")

    # Check hmtx structure
    print(f"\nhmtx table type: {type(hmtx)}")
    print(f"hmtx has metrics attr: {hasattr(hmtx, 'metrics')}")

    if hasattr(hmtx, 'metrics'):
        hmtx_keys = list(hmtx.metrics.keys())[:10]
        print(f"First 10 hmtx keys: {hmtx_keys}")
        print(f"hmtx keys type: {[type(k) for k in hmtx_keys[:3]]}")

    # Check glyph order
    glyph_order = font.getGlyphOrder()
    print(f"First 10 glyph names: {glyph_order[:10]}")

    # Check cmap
    sample_cmap = dict(list(cmap.items())[:5])
    print(f"Sample cmap entries: {sample_cmap}")

    return font

def extract_metrics_safe(font_path):
    """Safely extract metrics using direct access methods"""
    font = TTFont(font_path)

    head = font['head']
    hhea = font['hhea']
    hmtx = font['hmtx']
    cmap = font.getBestCmap()

    units_per_em = head.unitsPerEm
    glyph_set = font.getGlyphSet()

    # Use font-wide metrics as base
    font_height = hhea.ascender / units_per_em
    font_depth = -hhea.descender / units_per_em if hhea.descender < 0 else 0

    print(f"Font-wide metrics: height={font_height:.5f}, depth={font_depth:.5f}")

    metrics = {}

    # Test with basic ASCII characters
    for unicode_val in range(32, 127):
        if unicode_val in cmap:
            glyph_name = cmap[unicode_val]

            print(f"Processing {unicode_val} ({chr(unicode_val)}) -> '{glyph_name}'")

            try:
                # Try to get horizontal metrics directly
                try:
                    advance_width, lsb = hmtx.metrics[glyph_name]
                    print(f"  Found hmtx: width={advance_width}, lsb={lsb}")
                except KeyError:
                    print(f"  No hmtx for '{glyph_name}', skipping")
                    continue
                except Exception as e:
                    print(f"  hmtx access error: {e}")
                    continue

                # Try to get glyph bounds
                height = font_height  # default
                depth = font_depth    # default

                try:
                    if glyph_name in glyph_set:
                        glyph = glyph_set[glyph_name]
                        bounds_pen = BoundsPen(glyph_set)
                        glyph.draw(bounds_pen)
                        bounds = bounds_pen.bounds

                        if bounds:
                            x_min, y_min, x_max, y_max = bounds
                            height = y_max / units_per_em if y_max > 0 else font_height
                            depth = -y_min / units_per_em if y_min < 0 else 0
                            print(f"  Got bounds: {bounds}")
                        else:
                            print(f"  No bounds, using font defaults")
                    else:
                        print(f"  Glyph not in glyph_set, using font defaults")
                except Exception as e:
                    print(f"  Bounds error: {e}, using font defaults")

                # Calculate final metrics
                width = advance_width / units_per_em

                # Ensure reasonable values
                depth = max(0, depth)
                height = max(0, height)
                width = max(0, width)

                metrics[unicode_val] = {
                    'depth': round(depth, 5),
                    'height': round(height, 5),
                    'italic': 0.0,
                    'skew': 0.0,
                    'width': round(width, 5)
                }

                print(f"  Final: d={depth:.3f}, h={height:.3f}, w={width:.3f}")

            except Exception as e:
                print(f"  Error processing {unicode_val}: {e}")
                continue

    return metrics

def create_minimal_metrics(font_path):
    """Create minimal metrics using only basic font info"""
    font = TTFont(font_path)

    head = font['head']
    hhea = font['hhea']
    hmtx = font['hmtx']
    cmap = font.getBestCmap()

    units_per_em = head.unitsPerEm

    # Use fixed font-wide metrics
    font_height = 0.886  # From previous output
    font_depth = 0.374   # From previous output

    metrics = {}

    print(f"Creating minimal metrics with fixed values:")
    print(f"  Height: {font_height}")
    print(f"  Depth: {font_depth}")

    # Define standard character widths (approximated)
    standard_widths = {
        32: 0.25,   # space
        33: 0.28,   # !
        48: 0.5,    # 0
        49: 0.5,    # 1
        50: 0.5,    # 2
        51: 0.5,    # 3
        52: 0.5,    # 4
        53: 0.5,    # 5
        54: 0.5,    # 6
        55: 0.5,    # 7
        56: 0.5,    # 8
        57: 0.5,    # 9
        65: 0.6,    # A
        66: 0.6,    # B
        67: 0.6,    # C
        68: 0.6,    # D
        69: 0.55,   # E
        70: 0.55,   # F
        71: 0.65,   # G
        72: 0.6,    # H
        73: 0.25,   # I
        74: 0.45,   # J
        75: 0.6,    # K
        76: 0.5,    # L
        77: 0.7,    # M
        78: 0.6,    # N
        79: 0.65,   # O
        80: 0.55,   # P
        81: 0.65,   # Q
        82: 0.6,    # R
        83: 0.55,   # S
        84: 0.55,   # T
        85: 0.6,    # U
        86: 0.6,    # V
        87: 0.8,    # W
        88: 0.6,    # X
        89: 0.6,    # Y
        90: 0.55,   # Z
        97: 0.5,    # a
        98: 0.5,    # b
        99: 0.45,   # c
        100: 0.5,   # d
        101: 0.5,   # e
        102: 0.3,   # f
        103: 0.5,   # g
        104: 0.5,   # h
        105: 0.25,  # i
        106: 0.25,  # j
        107: 0.45,  # k
        108: 0.25,  # l
        109: 0.7,   # m
        110: 0.5,   # n
        111: 0.5,   # o
        112: 0.5,   # p
        113: 0.5,   # q
        114: 0.35,  # r
        115: 0.45,  # s
        116: 0.3,   # t
        117: 0.5,   # u
        118: 0.45,  # v
        119: 0.65,  # w
        120: 0.45,  # x
        121: 0.45,  # y
        122: 0.45,  # z
    }

    for unicode_val in range(32, 127):
        if unicode_val in cmap:
            width = standard_widths.get(unicode_val, 0.5)  # default width

            metrics[unicode_val] = {
                'depth': font_depth,
                'height': font_height,
                'italic': 0.0,
                'skew': 0.0,
                'width': width
            }

    return metrics

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate character metrics from a TTF font file.")
    parser.add_argument("font_path", help="Path to the .ttf font file")
    args = parser.parse_args()

    font_path = args.font_path

    try:
        print("=== Debugging font structure ===")
        debug_font_structure(font_path)

        print("\n=== Attempting safe extraction ===")
        metrics = extract_metrics_safe(font_path)

        if not metrics:
            print("\n=== Using minimal metrics approach ===")
            metrics = create_minimal_metrics(font_path)

        if metrics:
            print(f"\nGenerated metrics for {len(metrics)} characters")

            # Generate Dart code
            dart_output = f'  "{font_path.split("/")[-1].replace(".ttf", "")}": {{\n'
            for codepoint in sorted(metrics.keys()):
                metric = metrics[codepoint]
                dart_output += f'    {codepoint}: CharacterMetrics({metric["depth"]}, {metric["height"]}, {metric["italic"]}, {metric["skew"]}, {metric["width"]}),\n'
            dart_output += '  },'

            # Save to file
            with open(font_path.split('/')[-1].replace('.ttf', '_metrics.dart'), 'w') as f:
                f.write('// Generated font metrics\n')
                f.write('// Add this to your fontMetricsData map\n\n')
                f.write(dart_output)

            print(f"Dart code saved to {font_path.split('/')[-1].replace('.ttf', '_metrics.dart')}")

            # Show sample characters
            print("\nSample characters:")
            sample_chars = [32, 65, 66, 67, 97, 98, 99, 48, 49, 50]
            for codepoint in sample_chars:
                if codepoint in metrics:
                    char = chr(codepoint)
                    metric = metrics[codepoint]
                    print(f"  {codepoint} ('{char}'): CharacterMetrics({metric['depth']}, {metric['height']}, {metric['italic']}, {metric['skew']}, {metric['width']}),")
        else:
            print("All methods failed")

    except Exception as e:
        print(f"Script failed: {e}")
        traceback.print_exc()
