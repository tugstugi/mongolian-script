/* Pango
 * Shaper for Mongolian script
 *
 * Author: Erdene-Ochir Tuguldur <tugstugi@yahoo.com>
 *
 * Based on code from other shapers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * The license on the original Indic shaper code is as follows:
 *
 *  * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, and/or sell copies of the
 * Software, and to permit persons to whom the Software is furnished
 * to do so, provided that the above copyright notice(s) and this
 * permission notice appear in all copies of the Software and that
 * both the above copyright notice(s) and this permission notice
 * appear in supporting documentation.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR HOLDERS INCLUDED IN THIS NOTICE BE LIABLE FOR
 * ANY CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL DAMAGES, OR ANY
 * DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
 * WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
 * ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
 * OF THIS SOFTWARE.
 *
 * Except as contained in this notice, the name of a copyright holder
 * shall not be used in advertising or otherwise to promote the sale,
 * use or other dealings in this Software without prior written
 * authorization of the copyright holder.
 */
#include <string.h>

#include "pango-engine.h"
#include "pango-utils.h"
#include "pangofc-font.h"
#include "pango-ot.h"

enum  joining_type_
{
	isolated = 1,
	final    = 2,
	initial  = 4,
	medial   = 8
};

typedef enum joining_type_  joining_type;

/*
 * A glyph's property value as needed by e.g. TT_GSUB_Apply_String()
 * specifies which features should *not* be applied
 */
enum  mongolian_glyph_property_
{
	isolated_p = final    | initial | medial,
	final_p    = isolated | initial | medial,
	initial_p  = isolated | final   | medial,
	medial_p   = isolated | final   | initial
};

typedef enum mongolian_glyph_property_  mongolian_glyph_property;

enum  mongolian_character_class_
{
	letter,
	other
};

typedef enum mongolian_character_class_  mongolian_character_class;

static mongolian_character_class  Get_Character_Class (gunichar* string, int pos, int length, int direction)
{

	while(1) {
		if (pos == 0 && direction < 0)
			return other;

		pos += direction;

		if (pos >= length)
			return other;

		if (string[pos] >= 0x180B && string[pos] < 0x180E && direction != 0) // variation selector
			;
		else if (string[pos] == 0x180A && direction != 0) // mongolian niragu
			;
		else if (string[pos] == 0x200D && direction != 0) // zero with joining
			;
		else if (string[pos] == 0x180E) // mongolian vowel seperator
			return other;
		else if (string[pos] == 0x202F) // no break narrow space
			return other;
		else if (string[pos] >= 0x1800 && string[pos] < 0x1820)
			return other;
		else if (string[pos] >= 0x1820 && string[pos] < 0x1878)
			return letter;
		else if (string[pos] >= 0x1880 && string[pos] < 0x18AB)
			return letter;
		else
			return other;
	}
}


FT_Error  Mongolian_Assign_Properties (gunichar *string, gulong *properties, int length)
{
	mongolian_character_class  previous, current, next;
	int      i;

	if (!string || !properties || length == 0)
		return FT_Err_Invalid_Argument;

	for (i = 0; i < length; i++)
	{
		previous = Get_Character_Class (string, i, length, -1);
		current  = Get_Character_Class (string, i, length,  0);
		next     = Get_Character_Class (string, i, length,  1);

		if (current == letter)
		{
			if (previous == other && next == letter)
			{
				properties[i] |= initial_p;
				continue;
			}

			if (previous == letter && next == other)
			{
				properties[i] |= final_p;
				continue;
			}

			if (previous == letter && next == letter)
			{
				properties[i] |= medial_p;
				continue;
			}

			if (previous == other && next == other)
			{
				properties[i] |= isolated_p;
				continue;
			}
		}
	}

	return FT_Err_Ok;
}

typedef PangoEngineShape MongolianEngineFc;
typedef PangoEngineShapeClass MongolianEngineFcClass;

#define SCRIPT_ENGINE_NAME "MongolianScriptEngineFc"
#define RENDER_TYPE PANGO_RENDER_TYPE_FC

static PangoEngineScriptInfo mongolian_scripts[] = {
	{ PANGO_SCRIPT_MONGOLIAN, "*" }
};

static PangoEngineInfo script_engines[] = {
	{
		SCRIPT_ENGINE_NAME,
		PANGO_ENGINE_TYPE_SHAPE,
		RENDER_TYPE,
		mongolian_scripts,
		G_N_ELEMENTS(mongolian_scripts)
	}
};

static const PangoOTFeatureMap gsub_features[] =
{
	{"ccmp", PANGO_OT_ALL_GLYPHS},
	{"isol", isolated},
	{"fina", final},
	{"medi", medial},
	{"init", initial},
	{"rlig", PANGO_OT_ALL_GLYPHS},
	{"calt", PANGO_OT_ALL_GLYPHS}
};

static const PangoOTFeatureMap gpos_features[] =
{
	{"kern", PANGO_OT_ALL_GLYPHS},
	{"mark", PANGO_OT_ALL_GLYPHS}
};

static void
mongolian_engine_shape (PangoEngineShape *engine G_GNUC_UNUSED, PangoFont *font, const char *text, gint length, const PangoAnalysis *analysis, PangoGlyphString *glyphs)
{

	PangoFcFont *fc_font;
	FT_Face face;
	PangoOTRulesetDescription desc;
	const PangoOTRuleset *ruleset;
	PangoOTBuffer *buffer;
	gulong *properties = NULL;
	glong n_chars;
	gunichar *wcs;
	const char *p;
	int cluster = 0;
	gboolean rtl = analysis->level % 2 != 0;
	int i;

	g_return_if_fail (font != NULL);
	g_return_if_fail (text != NULL);
	g_return_if_fail (length >= 0);
	g_return_if_fail (analysis != NULL);

	fc_font = PANGO_FC_FONT (font);
	face = pango_fc_font_lock_face (fc_font);
	if (!face)
		return;

	buffer = pango_ot_buffer_new (fc_font);
	pango_ot_buffer_set_rtl (buffer, rtl);
	pango_ot_buffer_set_zero_width_marks (buffer, TRUE);

	wcs = g_utf8_to_ucs4_fast (text, length, &n_chars);
	properties = g_new0 (gulong, n_chars);

	Mongolian_Assign_Properties (wcs, properties, n_chars);

	g_free (wcs);

	p = text;
	for (i=0; i < n_chars; i++)
	{
		gunichar wc;
		PangoGlyph glyph;

		wc = g_utf8_get_char (p);

		if (g_unichar_type (wc) != G_UNICODE_NON_SPACING_MARK)
			cluster = p - text;

		if (pango_is_zero_width (wc))
			glyph = PANGO_GLYPH_EMPTY;
		else
		{
			gunichar c = wc;

			if (analysis->level % 2)
				g_unichar_get_mirror_char (c, &c);

			glyph = pango_fc_font_get_glyph (fc_font, c);
		}

		if (!glyph)
			glyph = PANGO_GET_UNKNOWN_GLYPH (wc);

		pango_ot_buffer_add_glyph (buffer, glyph, properties[i], cluster);

		p = g_utf8_next_char (p);
	}

	g_free (properties);

	desc.script = analysis->script;
	desc.language = analysis->language;

	desc.n_static_gsub_features = G_N_ELEMENTS (gsub_features);
	desc.static_gsub_features = gsub_features;
	desc.n_static_gpos_features = G_N_ELEMENTS (gpos_features);
	desc.static_gpos_features = gpos_features;

	/* TODO populate other_features from analysis->extra_attrs */
	desc.n_other_features = 0;
	desc.other_features = NULL;

	ruleset = pango_ot_ruleset_get_for_description (pango_ot_info_get (face), &desc);

	pango_ot_ruleset_substitute (ruleset, buffer);
	pango_ot_ruleset_position (ruleset, buffer);
	pango_ot_buffer_output (buffer, glyphs);

	pango_ot_buffer_destroy (buffer);

	pango_fc_font_unlock_face (fc_font);
}

static void mongolian_engine_fc_class_init(PangoEngineShapeClass *class) {
	class->script_shape = mongolian_engine_shape;
}

PANGO_ENGINE_SHAPE_DEFINE_TYPE (MongolianEngineFc, mongolian_engine_fc, mongolian_engine_fc_class_init, NULL)

void PANGO_MODULE_ENTRY(init) (GTypeModule *module)
{
	mongolian_engine_fc_register_type (module);
}

void PANGO_MODULE_ENTRY(exit)(void) {
}

void PANGO_MODULE_ENTRY( list)(PangoEngineInfo **engines, int *n_engines) {
	*engines = script_engines;
	*n_engines = G_N_ELEMENTS(script_engines);
}

PangoEngine * PANGO_MODULE_ENTRY( create) (const char *id)
{
	if (!strcmp (id, SCRIPT_ENGINE_NAME))
		return g_object_new (mongolian_engine_fc_type, NULL);
	else
		return NULL;
}
