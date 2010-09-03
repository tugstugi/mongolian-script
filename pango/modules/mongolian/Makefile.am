include $(top_srcdir)/modules/Module.mk

INCLUDES += $(FREETYPE_CFLAGS)
module_LTLIBRARIES += pango-mongolian-fc.la

fc_sources = \
	mongolian-fc.c

pango_mongolian_fc_la_LDFLAGS = -module $(MODULE_LIBTOOL_OPTIONS)
pango_mongolian_fc_la_LIBADD = $(pangoft2libs)
pango_mongolian_fc_la_SOURCES = $(fc_sources)
libpango_mongolian_fc_la_SOURCES = $(fc_sources)
libpango_mongolian_fc_la_CFLAGS = -DPANGO_MODULE_PREFIX=_pango_mongolian_fc

-include $(top_srcdir)/git.mk
