from fontTools.ttLib import TTFont
from fontTools.pens.boundsPen import BoundsPen
import traceback
import argparse

def extract_all_available_characters(font_path):
    """Extract metrics for ALL available characters in the font"""
    font = TTFont(font_path)

    head = font['head']
    hhea = font['hhea']
    hmtx = font['hmtx']
    cmap = font.getBestCmap()

    units_per_em = head.unitsPerEm
    glyph_set = font.getGlyphSet()

    # Use font-wide metrics as fallback
    font_height = hhea.ascender / units_per_em
    font_depth = -hhea.descender / units_per_em if hhea.descender < 0 else 0

    print(f"Font: {font_path}")
    print(f"Units per EM: {units_per_em}")
    print(f"Total glyphs in font: {len(font.getGlyphOrder())}")
    print(f"Characters in cmap: {len(cmap)}")
    print(f"Font-wide metrics: height={font_height:.5f}, depth={font_depth:.5f}")

    # Get all Unicode code points available in the font
    all_unicode_points = sorted(cmap.keys())
    print(f"Unicode range: {min(all_unicode_points)} - {max(all_unicode_points)}")

    # Show some sample ranges
    basic_latin = [cp for cp in all_unicode_points if 32 <= cp <= 126]
    latin_extended = [cp for cp in all_unicode_points if 127 <= cp <= 255]
    other_ranges = [cp for cp in all_unicode_points if cp > 255]

    print(f"Basic Latin (32-126): {len(basic_latin)} characters")
    print(f"Latin Extended (127-255): {len(latin_extended)} characters")
    print(f"Other ranges (>255): {len(other_ranges)} characters")

    if other_ranges:
        print(f"Sample other characters: {other_ranges[:20]}")

    metrics = {}
    processed = 0
    errors = 0

    print(f"\nProcessing all {len(all_unicode_points)} characters...")

    for i, unicode_val in enumerate(all_unicode_points):
        if i % 100 == 0:
            print(f"Progress: {i}/{len(all_unicode_points)} ({i/len(all_unicode_points)*100:.1f}%)")

        try:
            glyph_name = cmap[unicode_val]

            # Get horizontal metrics
            if glyph_name in hmtx.metrics:
                advance_width, lsb = hmtx.metrics[glyph_name]

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
                except:
                    # Use font defaults if bounds extraction fails
                    pass

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

                processed += 1
            else:
                errors += 1

        except Exception as e:
            errors += 1
            if errors <= 10:  # Only print first 10 errors
                print(f"Error processing {unicode_val}: {e}")

    print(f"\nSuccessfully processed: {processed} characters")
    print(f"Errors: {errors} characters")

    return metrics

def analyze_character_ranges(metrics):
    """Analyze and categorize the extracted characters"""
    if not metrics:
        return

    unicode_points = sorted(metrics.keys())

    print(f"\n=== Character Analysis ===")
    print(f"Total characters extracted: {len(unicode_points)}")

    # Categorize by Unicode ranges
    ranges = {
        'Basic Latin (0-127)': [cp for cp in unicode_points if 0 <= cp <= 127],
        'Latin-1 Supplement (128-255)': [cp for cp in unicode_points if 128 <= cp <= 255],
        'Latin Extended-A (256-383)': [cp for cp in unicode_points if 256 <= cp <= 383],
        'Latin Extended-B (384-591)': [cp for cp in unicode_points if 384 <= cp <= 591],
        'IPA Extensions (592-687)': [cp for cp in unicode_points if 592 <= cp <= 687],
        'Spacing Modifier Letters (688-767)': [cp for cp in unicode_points if 688 <= cp <= 767],
        'Combining Diacritical Marks (768-879)': [cp for cp in unicode_points if 768 <= cp <= 879],
        'Greek and Coptic (880-1023)': [cp for cp in unicode_points if 880 <= cp <= 1023],
        'General Punctuation (8192-8303)': [cp for cp in unicode_points if 8192 <= cp <= 8303],
        'Mathematical Operators (8704-8959)': [cp for cp in unicode_points if 8704 <= cp <= 8959],
        'Other ranges': [cp for cp in unicode_points if cp > 1023 and not (8192 <= cp <= 8303) and not (8704 <= cp <= 8959)]
    }

    for range_name, codepoints in ranges.items():
        if codepoints:
            print(f"{range_name}: {len(codepoints)} characters")
            if len(codepoints) <= 20:
                # Show all if small range
                chars = [f"{cp}('{chr(cp)}')" if 32 <= cp <= 126 else f"{cp}" for cp in codepoints[:20]]
                print(f"  {', '.join(chars)}")
            else:
                # Show first few
                chars = [f"{cp}('{chr(cp)}')" if 32 <= cp <= 126 else f"{cp}" for cp in codepoints[:10]]
                print(f"  First 10: {', '.join(chars)}")

def save_complete_metrics(metrics, font_name="Excalifont-Regular"):
    """Save all metrics to a Dart file"""
    if not metrics:
        print("No metrics to save!")
        return

    dart_output = f'  "{font_name}": {{\n'

    # Sort by Unicode code point
    for codepoint in sorted(metrics.keys()):
        metric = metrics[codepoint]
        dart_output += f'    {codepoint}: CharacterMetrics({metric["depth"]}, {metric["height"]}, {metric["italic"]}, {metric["skew"]}, {metric["width"]}),\n'

    dart_output += '  },'

    filename = f'{font_name.lower().replace("-", "_")}_complete_metrics.dart'

    with open(filename, 'w', encoding='utf-8') as f:
        f.write('// Complete font metrics for ' + font_name + '\n')
        f.write(f'// Total characters: {len(metrics)}\n')
        f.write('// Add this to your fontMetricsData map\n\n')
        f.write(dart_output)

    print(f"\nComplete metrics saved to: {filename}")
    return filename

def show_sample_characters(metrics, num_samples=20):
    """Show a sample of different character types"""
    if not metrics:
        return

    print(f"\n=== Sample Characters ===")

    # Basic Latin
    basic_latin = [(cp, metrics[cp]) for cp in sorted(metrics.keys()) if 32 <= cp <= 126]
    if basic_latin:
        print("Basic Latin sample:")
        for cp, metric in basic_latin[:10]:
            char = chr(cp)
            print(f"  {cp} ('{char}'): CharacterMetrics({metric['depth']}, {metric['height']}, {metric['italic']}, {metric['skew']}, {metric['width']}),")

    # Extended characters
    extended = [(cp, metrics[cp]) for cp in sorted(metrics.keys()) if cp > 126]
    if extended:
        print(f"\nExtended characters sample (first 10 of {len(extended)}):")
        for cp, metric in extended[:10]:
            try:
                char = chr(cp)
                char_display = char if ord(char) >= 32 else f"\\u{cp:04x}"
            except:
                char_display = f"\\u{cp:04x}"
            print(f"  {cp} ('{char_display}'): CharacterMetrics({metric['depth']}, {metric['height']}, {metric['italic']}, {metric['skew']}, {metric['width']}),")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate character metrics from a TTF font file.")
    parser.add_argument("font_path", help="Path to the .ttf font file")
    args = parser.parse_args()

    font_path = args.font_path

    try:
        print("=== Extracting ALL available characters ===")
        all_metrics = extract_all_available_characters(font_path)

        if all_metrics:
            analyze_character_ranges(all_metrics)
            show_sample_characters(all_metrics)
            filename = save_complete_metrics(all_metrics)

            print(f"\nSUCCESS!")
            print(f"Extracted metrics for {len(all_metrics)} characters")
            print(f"Saved to: {filename}")
            print(f"Ready to integrate into flutter_math!")

        else:
            print("Failed to extract any characters")

    except Exception as e:
        print(f"Script failed: {e}")
        traceback.print_exc()
