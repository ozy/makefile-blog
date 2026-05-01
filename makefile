BLOGNAME = Metin's Blog
BLOGDESC = Personal opinions and experiments about programming.
TEMPLATE = default
BLOGROOT = https://metin.nextc.org
# You may set blogroot your domain for non relative urls.
# RSS requires you to set the path absolute.
# Also dont put / at the end

INDEX = index.html
TITLESEPERATOR = $() | 
NUMINDEXPOSTS = 10
# space, |, space
# the way make treats spaces is interesting

POSTSDIR = posts
PAGESDIR = pages
BUILDDIR = build
STATICDIR = static
TEMPDIR = /tmp
TEMPLATESDIR = templates

TEMPLATEPATH := $(TEMPLATESDIR)/$(TEMPLATE)

POSTS := $(shell find $(POSTSDIR) -type f ! -path "$(POSTSDIR)/$(STATICDIR)/*" 2> /dev/null)
PAGES := $(shell find $(PAGESDIR) -type f ! -path "$(PAGESDIR)/$(STATICDIR)/*" 2> /dev/null)
HTMLPOSTS := $(patsubst $(POSTSDIR)/%,$(BUILDDIR)/$(POSTSDIR)/%.html,$(POSTS))
HTMLPAGES := $(patsubst $(PAGESDIR)/%,$(BUILDDIR)/$(PAGESDIR)/%.html,$(PAGES))

.PHONY: setup blog precheck index posts_index posts pages rss static_content clean
.NOTPARALLEL: setup precheck blog index posts_index rss static_content clean
.SILENT: static_content
blog: precheck index rss posts_index posts pages static_content

SHELL := /bin/bash

escape_quote = $(subst ',\',$(1))

BLOGNAMEESC := $(call escape_quote,$(BLOGNAME))
BLOGDESCESC := $(call escape_quote,$(BLOGDESC))
TITLESEPERATORESC := $(call escape_quote,$(TITLESEPERATOR))

define metadata_value
awk -v key="$(1)" 'tolower($$0) ~ /^[ \t]*<meta[ \t]/ { name = ""; content = ""; if (match($$0, /name="[^"]*"/)) { name = substr($$0, RSTART + 6, RLENGTH - 7) } if (match($$0, /content="[^"]*"/)) { content = substr($$0, RSTART + 9, RLENGTH - 10) } if (tolower(name) == tolower(key)) { print content; exit } }' "$(2)"
endef

define post_body
awk 'tolower($$0) ~ /^[ \t]*<meta[ \t]/ && tolower($$0) ~ /name="(title|author|date|updated|description)"/ { next } { print }' "$(1)"
endef

define sorted_posts
for post in $(POSTS); do POST_DATE=$$($(call metadata_value,date,$$post)); if [ -z "$$POST_DATE" ]; then echo "Missing required metadata 'date' in $$post" >&2; exit 1; fi; printf "%s\t%s\n" "$$POST_DATE" "$$post"; done | sort -r | cut -f2-
endef

# INDEX PAGE
$(BUILDDIR)/$(INDEX): $(POSTS) $(TEMPLATEPATH)/index.html $(TEMPLATEPATH)/post_card.html $(TEMPDIR)/blog_menu_items
	rm -f $(TEMPDIR)/blog_index_posts
	for post in $$($(call sorted_posts) | head -n $(NUMINDEXPOSTS)); do \
		POST_TITLE=$$($(call metadata_value,title,$$post)); \
		POST_AUTHOR=$$($(call metadata_value,author,$$post)); \
		POST_DATE=$$($(call metadata_value,date,$$post)); \
		POST_DATE_UPDATED=$$($(call metadata_value,updated,$$post)); \
		POST_DESC=$$($(call post_body,$$post) | TEMPLATE_STATIC_PATH=$$'$(BLOGROOT)/$(STATICDIR)' envsubst | sed 's/<[^>]*>//g' | tr '\n' ' ' | cut -d' ' -f 1-100)...; \
		if [ -z "$$POST_TITLE" ] || [ -z "$$POST_AUTHOR" ] || [ -z "$$POST_DATE" ] || [ -z "$$POST_DATE_UPDATED" ]; then echo "Missing required metadata in $$post" >&2; exit 1; fi; \
		TEMPLATE_POST_TITLE="$$POST_TITLE" \
		TEMPLATE_BLOG_ROOT=$$'$(BLOGROOT)' \
		TEMPLATE_POST_URL=$$(echo $$post).html \
		TEMPLATE_STATIC_PATH=$$'$(BLOGROOT)/$(STATICDIR)' \
		TEMPLATE_POST_AUTHOR="$$POST_AUTHOR" \
		TEMPLATE_POST_DATE="$$POST_DATE" \
		TEMPLATE_POST_DATE_UPDATED="$$POST_DATE_UPDATED" \
		TEMPLATE_POST_DESC="$$POST_DESC" \
		envsubst < "$(TEMPLATEPATH)/post_card.html" >> $(TEMPDIR)/blog_index_posts ; \
	done
	TEMPLATE_TITLE=$$'$(BLOGNAMEESC)' \
	TEMPLATE_DESC=$$'$(BLOGDESCESC)' \
	TEMPLATE_EXTRA_MENU_ITEMS=$$(cat $(TEMPDIR)/blog_menu_items) \
	TEMPLATE_PAGE_TITLE=$$'Latest Posts' \
	TEMPLATE_BLOG_ROOT=$$'$(BLOGROOT)' \
	TEMPLATE_BODY=$$(cat $(TEMPDIR)/blog_index_posts) \
	envsubst < "$(TEMPLATEPATH)/index.html" > $@

# POSTS INDEX
$(BUILDDIR)/$(POSTSDIR)/index.html: $(POSTS) $(TEMPLATEPATH)/post.html $(TEMPLATEPATH)/post_index_card.html $(TEMPDIR)/blog_menu_items
	rm -f $(TEMPDIR)/blog_index_all_posts
	for post in $$($(call sorted_posts)); do \
		POST_TITLE=$$($(call metadata_value,title,$$post)); \
		POST_DATE=$$($(call metadata_value,date,$$post)); \
		if [ -z "$$POST_TITLE" ] || [ -z "$$POST_DATE" ]; then echo "Missing required metadata in $$post" >&2; exit 1; fi; \
		TEMPLATE_POST_TITLE="$$POST_TITLE" \
		TEMPLATE_BLOG_ROOT=$$'$(BLOGROOT)' \
		TEMPLATE_POST_URL=$$(echo $$post).html \
		TEMPLATE_POST_DATE="$$POST_DATE" \
		envsubst < "$(TEMPLATEPATH)/post_index_card.html" >> $(TEMPDIR)/blog_index_all_posts ; \
	done
	TEMPLATE_TITLE=$$'$(BLOGNAMEESC)' \
	TEMPLATE_DESC=$$'$(BLOGDESCESC)' \
	TEMPLATE_EXTRA_MENU_ITEMS=$$(cat $(TEMPDIR)/blog_menu_items) \
	TEMPLATE_PAGE_TITLE=$$'All Posts' \
	TEMPLATE_BLOG_ROOT=$$'$(BLOGROOT)' \
	TEMPLATE_BODY=$$(cat $(TEMPDIR)/blog_index_all_posts) \
	envsubst < "$(TEMPLATEPATH)/page.html" > $@

# MENU ITEMS
$(TEMPDIR)/blog_menu_items: $(PAGES) $(TEMPLATEPATH)/menu_item.html
	rm -f $(TEMPDIR)/blog_menu_items
	touch $(TEMPDIR)/blog_menu_items

	for page in $(PAGES); do \
		PAGE_TITLE=$$($(call metadata_value,title,$$page)); \
		if [ -z "$$PAGE_TITLE" ]; then echo "Missing required metadata 'title' in $$page" >&2; exit 1; fi; \
		TEMPLATE_BLOG_ROOT=$$'$(BLOGROOT)' \
		TEMPLATE_PAGE_URL=$$(echo $$page).html \
		TEMPLATE_PAGE_NAME="$$PAGE_TITLE" \
		envsubst < "$(TEMPLATEPATH)/menu_item.html" >> $@ ; \
	done

# RSS
$(BUILDDIR)/RSS.xml: $(POSTS) $(TEMPLATEPATH)/RSS.xml $(TEMPLATEPATH)/RSS_item.xml
	rm -f $(TEMPDIR)/blog_rss_items
	for post in $$($(call sorted_posts) | head -n $(NUMINDEXPOSTS)); do \
		POST_TITLE=$$($(call metadata_value,title,$$post)); \
		POST_AUTHOR=$$($(call metadata_value,author,$$post)); \
		POST_DATE=$$($(call metadata_value,date,$$post)); \
		POST_DATE_UPDATED=$$($(call metadata_value,updated,$$post)); \
		POST_DESC=$$($(call post_body,$$post) | sed 's/<[^>]*>//g' | tr '\n' ' ' | cut -d' ' -f 1-100)...; \
		if [ -z "$$POST_TITLE" ] || [ -z "$$POST_AUTHOR" ] || [ -z "$$POST_DATE" ] || [ -z "$$POST_DATE_UPDATED" ]; then echo "Missing required metadata in $$post" >&2; exit 1; fi; \
		TEMPLATE_POST_TITLE="$$POST_TITLE" \
		TEMPLATE_BLOG_ROOT=$$'$(BLOGROOT)' \
		TEMPLATE_POST_URL=$$(echo $$post).html \
		TEMPLATE_POST_AUTHOR="$$POST_AUTHOR" \
		TEMPLATE_POST_DATE="$$POST_DATE" \
		TEMPLATE_POST_DATE_UPDATED="$$POST_DATE_UPDATED" \
		TEMPLATE_POST_DESC="$$POST_DESC" \
		envsubst < "$(TEMPLATEPATH)/RSS_item.xml" >> $(TEMPDIR)/blog_rss_items ; \
	done
	TEMPLATE_TITLE=$$'$(BLOGNAMEESC)' \
	TEMPLATE_DESC=$$'$(BLOGDESCESC)' \
	TEMPLATE_EXTRA_MENU_ITEMS=$$(cat $(TEMPDIR)/blog_menu_items) \
	TEMPLATE_BLOG_ROOT=$$'$(BLOGROOT)' \
	TEMPLATE_RSS_ITEMS=$$(cat $(TEMPDIR)/blog_rss_items) \
	envsubst < "$(TEMPLATEPATH)/RSS.xml" > $@

# INDIVIDUAL POSTS
$(BUILDDIR)/$(POSTSDIR)/%.html: $(POSTSDIR)/% $(TEMPLATEPATH)/post.html $(TEMPDIR)/blog_menu_items
	POST_TITLE=$$($(call metadata_value,title,$<)); \
	POST_AUTHOR=$$($(call metadata_value,author,$<)); \
	POST_DATE=$$($(call metadata_value,date,$<)); \
	POST_DATE_UPDATED=$$($(call metadata_value,updated,$<)); \
	if [ -z "$$POST_TITLE" ] || [ -z "$$POST_AUTHOR" ] || [ -z "$$POST_DATE" ] || [ -z "$$POST_DATE_UPDATED" ]; then echo "Missing required metadata in $<" >&2; exit 1; fi; \
	TEMPLATE_BODY=$$($(call post_body,$<) | TEMPLATE_STATIC_PATH=$$'$(BLOGROOT)/$(STATICDIR)' envsubst); \
	TEMPLATE_TITLE="$${POST_TITLE}"$$'$(TITLESEPERATORESC)$(BLOGNAMEESC)' \
	TEMPLATE_EXTRA_MENU_ITEMS=$$(cat $(TEMPDIR)/blog_menu_items) \
	TEMPLATE_BLOG_ROOT=$$'$(BLOGROOT)' \
	TEMPLATE_POST_TITLE="$${POST_TITLE}" \
	TEMPLATE_STATIC_PATH=$$'$(BLOGROOT)/$(STATICDIR)' \
	TEMPLATE_POST_AUTHOR="$${POST_AUTHOR}" \
	TEMPLATE_POST_DATE="$${POST_DATE}" \
	TEMPLATE_POST_DATE_UPDATED="$${POST_DATE_UPDATED}" \
	TEMPLATE_BODY="$${TEMPLATE_BODY}" \
	envsubst < $$'$(TEMPLATEPATH)/post.html' > $@

# INDIVIDUAL PAGES
$(BUILDDIR)/$(PAGESDIR)/%.html: $(PAGESDIR)/% $(TEMPLATEPATH)/page.html $(TEMPDIR)/blog_menu_items
	PAGE_TITLE=$$($(call metadata_value,title,$<)); \
	PAGE_AUTHOR=$$($(call metadata_value,author,$<)); \
	PAGE_DATE=$$($(call metadata_value,date,$<)); \
	PAGE_DATE_UPDATED=$$($(call metadata_value,updated,$<)); \
	if [ -z "$$PAGE_TITLE" ] || [ -z "$$PAGE_AUTHOR" ] || [ -z "$$PAGE_DATE" ] || [ -z "$$PAGE_DATE_UPDATED" ]; then echo "Missing required metadata in $<" >&2; exit 1; fi; \
	TEMPLATE_BODY=$$($(call post_body,$<) | TEMPLATE_STATIC_PATH=$$'$(BLOGROOT)/$(STATICDIR)' envsubst); \
	TEMPLATE_TITLE="$${PAGE_TITLE}"$$'$(TITLESEPERATORESC)$(BLOGNAMEESC)' \
	TEMPLATE_EXTRA_MENU_ITEMS=$$(cat $(TEMPDIR)/blog_menu_items) \
	TEMPLATE_BLOG_ROOT=$$'$(BLOGROOT)' \
	TEMPLATE_PAGE_TITLE="$${PAGE_TITLE}" \
	TEMPLATE_STATIC_PATH=$$'$(BLOGROOT)/$(STATICDIR)' \
	TEMPLATE_PAGE_AUTHOR="$${PAGE_AUTHOR}" \
	TEMPLATE_PAGE_DATE="$${PAGE_DATE}" \
	TEMPLATE_PAGE_DATE_UPDATED="$${PAGE_DATE_UPDATED}" \
	TEMPLATE_BODY="$${TEMPLATE_BODY}" \
	envsubst < $$'$(TEMPLATEPATH)/page.html' > $@

$(TEMPLATESDIR)/$(TEMPLATE)/%.html:
	$(error Template file for "$(TEMPLATE)" not found: $@)

index: $(BUILDDIR)/$(INDEX)
posts_index: $(BUILDDIR)/$(POSTSDIR)/$(INDEX)
posts: $(HTMLPOSTS)
pages: $(HTMLPAGES)
rss: $(BUILDDIR)/RSS.xml

static_content:
	cp -ar $(POSTSDIR)/$(STATICDIR)/* $(BUILDDIR)/$(STATICDIR)/ 2> /dev/null || echo $$'Info: No static file under $(POSTSDIR)/$(STATICDIR)'
	cp -ar $(PAGESDIR)/$(STATICDIR)/* $(BUILDDIR)/$(STATICDIR)/ 2> /dev/null || echo $$'Info: No static file under $(PAGESDIR)/$(STATICDIR)'
	cp $(TEMPLATEPATH)/*.css $(BUILDDIR)/$(STATICDIR)/ 2> /dev/null || echo $$'Info: No css file under $(TEMPLATEPATH)'

setup:
	mkdir -p $(POSTSDIR)
	mkdir -p $(PAGESDIR)

precheck:
ifeq ($(POSTS),)
	$(error No blog post found under $(POSTSDIR))
endif
	mkdir -p $(BUILDDIR)/$(POSTSDIR)/
	mkdir -p $(BUILDDIR)/$(PAGESDIR)/
	mkdir -p $(BUILDDIR)/$(STATICDIR)/css

clean:
	rm -rf $(BUILDDIR)
	rm -f $(TEMPDIR)/blog_rss_items $(TEMPDIR)/blog_index_posts $(TEMPDIR)/blog_index_all_posts $(TEMPDIR)/blog_menu_items
