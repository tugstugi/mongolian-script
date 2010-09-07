include $(top_srcdir)/modules/Module.mk

if HAVE_FREETYPE
INCLUDES += $(FREETYPE_CFLAGS)
if INCLUDE_MONGOLIAN_FC
noinst_LTLIBRARIES += libpango-mongolian-fc.la
else
if DYNAMIC_MONGOLIAN_FC
module_LTLIBRARIES += pango-mongolian-fc.la
endif
endif
endif

mongolian_fc_sources = $(common_sources) mongolian-fc.c

pango_mongolian_fc_la_LDFLAGS = -module $(MODULE_LIBTOOL_OPTIONS)
pango_mongolian_fc_la_LIBADD = $(pangoft2libs)
pango_mongolian_fc_la_SOURCES = $(mongolian_fc_sources)
libpango_mongolian_fc_la_SOURCES = $(mongolian_fc_sources)
libpango_mongolian_fc_la_CFLAGS = -DPANGO_MODULE_PREFIX=_pango_mongolian_fc

-include $(top_srcdir)/git.mk
