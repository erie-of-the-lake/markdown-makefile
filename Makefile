#!/usr/bin/env make

#############
# Variables #
#############

SHELL := /usr/bin/bash

PANDOC       := /usr/bin/pandoc
TEMPLATE_DIR := $${HOME}/Documents/Templates/
# uses eisvogel template
# can be found at https://github.com/Wandmalfarbe/pandoc-latex-template 
TEMPLATE     := eisvogel.latex
# this is for code blocks with numbered lines using eisvogel template
LISTINGS     := true

# non-markdown filetypes
# needed for passing arguments into pandoc
FILETYPE_DICT := ["docx"]=docx ["epub"]=epub3 ["txt"]=plain ["pdf"]=pdf ["odt"]=odt ["txt"]=txt

define get_pandoc_format
	declare -A dict=( $(FILETYPE_DICT) 'end-of-loop' );    \
	for input_format in "$${dict[@]}"; do                  \
		if [ "$${input_format}" = "$(1)" ]; then           \
			echo "$${dict[$${input_format}]}";             \
			break;                                         \
		elif [ "$${input_format}" = "end-of-loop" ]; then  \
			exit 1;                                        \
		fi;                                                \
	done
endef

define return_listing_arg
	if [ $(LISTINGS) = true ]; then \
		echo "--listings";          \
	else;                           \
		echo ''                     \
	fi
endef

# need to pass in either 'keys' or 'values' to get corresponding parts from $(FILETYPE_DICT)
define return_filetype_dict
	declare -A dict=( $(FILETYPE_DICT) );                \
	to_return=();                                        \
	for key in "$${dict[@]}"; do                         \
		if [ $(1) = 'key' || $(1) = 'keys' ]; then       \
			$${to_return}+=( "$${key}" );                \
		elif [ $(1) = 'value' || $(1) = 'values' ]; then \
			$${to_return}+=( "$${dict[$${key}]}" );      \
		else;                                            \
			exit 1;                                      \
		fi;                                              \
	done                                                 \
	echo "$${to_return}"
endef
		


# default arguments
PANDOC_DOCX_ARGS := --to=$(call get_pandoc_format,'docx')
PANDOC_EPUB_ARGS := --to=$(call get_pandoc_format,'epub')
PANDOC_HTML_ARGS := --to=html5
PANDOC_PDF_ARGS  := --to=$(call get_pandoc_format,'pdf') --template $(TEMPLATE_DIR)$(TEMPLATE) $(call return_listing_arg)
PANDOC_ODT_ARGS  := --to=$(call get_pandoc_format,'odt')
PANDOC_TXT_ARGS  := --to=$(call get_pandoc_format,'txt')

# markdown args
PANDOC_FROM_MD_ARGS := --from=markdown
PANDOC_TO_MD_ARGS   := --to=markdown

target := example
target_file := $(target).md

# do not clean when using "make clean"
NOCLEAN := $(target).md $(target).pdf Makefile


#################
# Main Commands #
#################

.PHONY: all clean draft pdf text
pdf: $(target).pdf

all: $(target_file)
	@for format in ( $(call return_filetype_dict,keys) ); do \
		$(MAKE) $(target).$${format};                        \
	done

draft: $(target_file)
	@draft_name="$(target)_draft-$$(date +%F)"; \
	cp $(target_file) $${draft_name}.md;        \
	$(MAKE) $${draft_name}.pdf;                 \
	rm $${draft_name}.md

text: $(target).txt

from-%:
	filetype=$(patsubst from-%,%,$@);                     \
	pandoc_format=$(call get_pandoc_format,$${filetype}); \
	$(PANDOC) --from=$${pandoc_format} $(PANDOC_TO_MD_ARGS) $(target).$${filetype} -o $(target).md.$${filetype}bak

####################
# Pattern-Matching #
####################

%.docx: %.md
	$(PANDOC) $(PANDOC_FROM_MD_ARGS) $(PANDOC_DOCX_ARGS) $< -o $@

%.epub: %.md
	$(PANDOC) $(PANDOC_FROM_MD_ARGS) $(PANDOC_EPUB_ARGS) $< -o $@

%.html: %.md
	$(PANDOC) $(PANDOC_FROM_MD_ARGS) $(PANDOC_HTML_ARGS) $< -o $@

%.pdf: %.md
	$(PANDOC) $(PANDOC_FROM_MD_ARGS) $(PANDOC_PDF_ARGS) $< -o $@

%.odt: %.md
	$(PANDOC) $(PANDOC_FROM_MD_ARGS) $(PANDOC_ODT_ARGS) $< -o $@

%.txt: %.md
	$(PANDOC) $(PANDOC_FROM_MD_ARGS) $(PANDOC_TXT_ARGS) $< -o $@


# Can't figure out how to make this more efficient at the cost of making it less
# readable. Currently, the problem lies with the $noclean array. I want `make 
# clean` to be space-agnostic in terms of working with file names. Hence, I would 
# need to make a new array with the elements of $(NOCLEAN) but with an IFS set to
# something different than " ".
# 
# Example in make syntax:
# 	if [ "$${IFS}$${noclean[*]}$${IFS}" =~ "$${IFS}$${file}$${IFS}" ]; then ...
# which basically means "if ${file} is an element of ${noclean}, then..."
#
# Note: $$(: "# comment") signifies an in-line comment.
clean:
	@$$(: "# 'end-of-loop' needed for for-else behavior"); \
	noclean=( $(NOCLEAN) "end-of-loop" );            \
	for file in ./*; do                              \
		$$(: "# remove prepending ./");              \
		file=$$(echo "$${file}" | sed "s_./__g") ;   \
		for file2 in $${noclean[@]}; do              \
			if [ "$${file}" = "$${file2}" ]; then    \
				break;                               \
			fi;                                      \
			if [ "$${file2}" = "end-of-loop" ]; then \
				rm -v "$${file}";                    \
			fi;                                      \
		done;                                        \
	done 
