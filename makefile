BLOGNAME = My First Blog
BLOGDESC = hey
TEMPLATE = default
BLOGROOT =
# You may set blogroot your domain for non relative urls.
# RSS requires you to set the path absolute.
# Also dont put / at the end

INDEX = index.html
TITLESEPERATOR = $() | 
NUMINDEXPOSTS = 10
# space, |, space
# the way make treats spaces is interesting

POSTSDIR = posts
BUILDDIR = build
STATICDIR = static
TEMPDIR = /tmp
TEMPLATESDIR = templates

TEMPLATEPATH := $(TEMPLATESDIR)/$(TEMPLATE)

POSTS := $(shell find $(POSTSDIR) -type f ! -path "$(POSTSDIR)/$(STATICDIR)/*")
HTMLPOSTS := $(patsubst $(POSTSDIR)/%,$(BUILDDIR)/$(POSTSDIR)/%.html,$(POSTS))

SHELL := /bin/bash

escape_quote = $(subst ',\',$(1))

BLOGNAMEESC := $(call escape_quote,$(BLOGNAME))
BLOGDESCESC := $(call escape_quote,$(BLOGDESC))
TITLESEPERATORESC := $(call escape_quote,$(TITLESEPERATOR))

ifeq ($(POSTS),)
$(error No blog post found under $(POSTSDIR))
endif

.PHONY: setup blog index posts_index posts rss static_content clean
.NOTPARALLEL: setup blog index posts_index rss static_content clean
.SILENT: static_content
blog: setup index rss posts_index posts static_content

# INDEX PAGE
$(BUILDDIR)/$(INDEX): $(POSTS) $(TEMPLATEPATH)/index.html $(TEMPLATEPATH)/post_card.html
	rm -f $(TEMPDIR)/blog_index_posts
	for post in $$(ls -t $(POSTS) | tr '\n' ' ' | cut -d' ' -f 1-$(NUMINDEXPOSTS)); do \
		TEMPLATE_POST_TITLE=$$(basename $$post | sed 's/_/ /g') \
		TEMPLATE_BLOG_ROOT=$$'$(BLOGROOT)' \
		TEMPLATE_POST_URL=$$(echo $$post).html \
		TEMPLATE_STATIC_PATH=$$'$(BLOGROOT)/$(STATICDIR)' \
		TEMPLATE_POST_AUTHOR=$$(stat -c '%U' $$post) \
		TEMPLATE_POST_DATE=$$(stat -c '%.19w' $$post) \
		TEMPLATE_POST_DATE_UPDATED=$$(stat -c '%.19y' $$post) \
		TEMPLATE_POST_DESC=$$(envsubst < $$post | sed 's/<[^>]*>//g' | tr '\n' ' ' | cut -d' ' -f 1-100)... \
		envsubst < "$(TEMPLATEPATH)/post_card.html" >> $(TEMPDIR)/blog_index_posts ; \
	done
	TEMPLATE_TITLE=$$'$(BLOGNAMEESC)' \
	TEMPLATE_DESC=$$'$(BLOGDESCESC)' \
	TEMPLATE_PAGE_TITLE=$$'Latest Posts' \
	TEMPLATE_BLOG_ROOT=$$'$(BLOGROOT)' \
	TEMPLATE_BODY=$$(cat $(TEMPDIR)/blog_index_posts) \
	envsubst < "$(TEMPLATEPATH)/index.html" > $@

# POSTS INDEX
$(BUILDDIR)/$(POSTSDIR)/index.html: $(POSTS) $(TEMPLATEPATH)/post_index_card.html
	rm -f $(TEMPDIR)/blog_index_all_posts
	for post in $$(ls -t $(POSTS)); do \
		TEMPLATE_POST_TITLE=$$(basename $$post | sed 's/_/ /g') \
		TEMPLATE_BLOG_ROOT=$$'$(BLOGROOT)' \
		TEMPLATE_POST_URL=$$(echo $$post).html \
		TEMPLATE_POST_DATE=$$(stat -c '%.19w' $$post) \
		envsubst < "$(TEMPLATEPATH)/post_index_card.html" >> $(TEMPDIR)/blog_index_all_posts ; \
	done
	TEMPLATE_TITLE=$$'$(BLOGNAMEESC)' \
	TEMPLATE_DESC=$$'$(BLOGDESCESC)' \
	TEMPLATE_PAGE_TITLE=$$'All Posts' \
	TEMPLATE_BLOG_ROOT=$$'$(BLOGROOT)' \
	TEMPLATE_BODY=$$(cat $(TEMPDIR)/blog_index_all_posts) \
	envsubst < "$(TEMPLATEPATH)/page.html" > $@

# RSS
$(BUILDDIR)/RSS.xml: $(POSTS) $(TEMPLATEPATH)/RSS.xml $(TEMPLATEPATH)/RSS_item.xml
	rm -f $(TEMPDIR)/blog_rss_items
	for post in $$(ls -t $(POSTS) | tr '\n' ' ' | cut -d' ' -f 1-$(NUMINDEXPOSTS)); do \
		TEMPLATE_POST_TITLE=$$(basename $$post | sed 's/_/ /g') \
		TEMPLATE_BLOG_ROOT=$$'$(BLOGROOT)' \
		TEMPLATE_POST_URL=$$(echo $$post).html \
		TEMPLATE_POST_AUTHOR=$$(stat -c '%U' $$post) \
		TEMPLATE_POST_DATE=$$(stat -c '%.19w' $$post) \
		TEMPLATE_POST_DATE_UPDATED=$$(stat -c '%.19y' $$post) \
		TEMPLATE_POST_DESC=$$(cat $$post | sed 's/<[^>]*>//g' | tr '\n' ' ' | cut -d' ' -f 1-100)... \
		envsubst < "$(TEMPLATEPATH)/RSS_item.xml" >> $(TEMPDIR)/blog_rss_items ; \
	done
	TEMPLATE_TITLE=$$'$(BLOGNAMEESC)' \
	TEMPLATE_DESC=$$'$(BLOGDESCESC)' \
	TEMPLATE_BLOG_ROOT=$$'$(BLOGROOT)' \
	TEMPLATE_RSS_ITEMS=$$(cat $(TEMPDIR)/blog_rss_items) \
	envsubst < "$(TEMPLATEPATH)/RSS.xml" > $@

# INDIVIDUAL POSTS
$(BUILDDIR)/$(POSTSDIR)/%.html: $(POSTSDIR)/% $(TEMPLATEPATH)/post.html
	$(eval PAGETITLE := $(subst _, ,$<))
	$(eval POSTTITLE := $(patsubst $(POSTSDIR)/%,%,$(PAGETITLE)))
	$(eval POSTTITLE := $(call escape_quote,$(POSTTITLE)))

	$(eval PAGETITLE := $(POSTTITLE)${TITLESEPERATORESC}$(BLOGNAMEESC))
	
	TEMPLATE_TITLE=$$'$(PAGETITLE)' \
	TEMPLATE_BLOG_ROOT=$$'$(BLOGROOT)' \
	TEMPLATE_POST_TITLE=$$'$(POSTTITLE)' \
	TEMPLATE_STATIC_PATH=$$'$(BLOGROOT)/$(STATICDIR)' \
	TEMPLATE_POST_AUTHOR=$$(stat -c '%U' $<) \
	TEMPLATE_POST_DATE=$$(stat -c '%.19w' $<) \
	TEMPLATE_POST_DATE_UPDATED=$$(stat -c '%.19y' $<) \
	TEMPLATE_BODY=$$(envsubst < $$'$<') \
	envsubst < $$'$(TEMPLATEPATH)/post.html' > $@

$(TEMPLATESDIR)/$(TEMPLATE)/%.html:
	$(error Template file for "$(TEMPLATE)" not found: $@)

index: $(BUILDDIR)/$(INDEX)
posts_index: $(BUILDDIR)/$(POSTSDIR)/$(INDEX)
posts: $(HTMLPOSTS)
rss: $(BUILDDIR)/RSS.xml

static_content:
	cp -ar $(POSTSDIR)/$(STATICDIR)/* $(BUILDDIR)/$(STATICDIR)/ 2> /dev/null || echo $$'Info: No static file under $(STATICDIR)'
	cp $(TEMPLATEPATH)/*.css $(BUILDDIR)/$(STATICDIR)/ 2> /dev/null || echo $$'Info: No css file under $(TEMPLATEPATH)'

setup:
	mkdir -p $(BUILDDIR)/$(POSTSDIR)/
	mkdir -p $(BUILDDIR)/$(STATICDIR)/css

clean:
	rm -rf $(BUILDDIR)
	rm -f $(TEMPDIR)/blog_rss_items $(TEMPDIR)/blog_index_posts $(TEMPDIR)/blog_index_all_posts