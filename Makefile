##############################################################################
# Document-specific settings
##############################################################################

# Only used to name the archive file.
PROJECT := physgwe

TARGETS := solutions.pdf flashcards.pdf
DEPS_DIR := .deps

# latexmk handles most of the cleaning. Set any additional things to be
# cleaned manually here.
DISTCLEAN_EXTRA := \
	$(TARGETS:.pdf=.auxlock) $(wildcard tikz/*)

# The archive will be built using files listed by -recorder option with the
# TeX distribution's files filtered out. Here, arbitrary extra files can be
# included as well.
ARCHIVE_EXTRA := Makefile

##############################################################################
# Generic processing setup
##############################################################################

LATEX ?= $(shell which lualatex 2>/dev/null)
LATEXFLAGS ?= -shell-escape -halt-on-error

LATEXMK ?= $(shell which latexmk 2>/dev/null)
LATEXMKFLAGS ?= \
	-pdf -dvi- -ps- -pv- -pvc- \
	-recorder -use-make -deps -deps-out=$(DEPS_DIR)/$@.d \
	-pdflatex='$(LATEX) %O $(LATEXFLAGS) %B' \
	-e 'warn qq(In Makefile, turn off custom dependencies\n);' \
	-e '@cus_dep_list = ();' \
	-e 'show_cus_dep();'

##############################################################################
# Rules
##############################################################################

.PHONY: clean dist-clean

# Compile all target PDFs
all: $(DEPS_DIR) $(TARGETS)

# Load dependencies
$(foreach file,$(TARGETS),$(eval -include $(DEPS_DIR)/$(file).d))
$(DEPS_DIR):
	@mkdir -p $@

###########################
# Compile primary document
###########################
%.pdf: %.tex $(DEPS_DIR) Makefile
	$(LATEXMK) $(LATEXMKFLAGS) $<

########################
# Clean standard output
########################
clean:
	for file in $(TARGETS:.pdf=); do $(LATEXMK) -c $$file; done

###################
# Clean everything
###################
dist-clean:
	for file in $(TARGETS:.pdf=); do $(LATEXMK) -C $$file; done
	rm -fr $(TARGETS:.pdf=.bbl)
	rm -fr $(DEPS_DIR)
	if [ ! -z "$(DISTCLEAN_EXTRA)" ]; then rm -fr $(DISTCLEAN_EXTRA); fi

#################################
# Create a distributable archive
#################################

# We need the file listing to know what to archive. The listing is created
# during compile, so launch a compile if necessary.
%.fls: %.pdf
	@true

archive: $(TARGETS:.pdf=.fls)
	@true; \
	# Generate a temporary directory build the tar file. \
	TMPDIR=$$(mktemp -d); \
	mkdir "$${TMPDIR}/$(PROJECT)"; \
	#echo -e "TMPDIR: $${TMPDIR};\n"; \
	# Then loop through each target to copy files to the temp directory. \
	for target in $(TARGETS:.pdf=); do \
		true; \
		# Examine the recorder list for inputs and outputs: \
		EXFILES="$$(cat "$${target}.fls" | egrep '^OUTPUT ' | \
			sed -e 's/^OUTPUT //' | sort | uniq | \
			egrep -v "^$${target}.pdf")"; \
		DEPFILES="$$(cat "$${target}.fls" | egrep '^INPUT ' | \
			sed -e 's/^INPUT //' | sort | uniq)"; \
		# Remove the current working path any files read in as an input. The \
		# listed outputs don't include the prefix, so make them consistent \
		# before filtering. \
		DEPFILES="$$(echo "$${DEPFILES}" | sed -e "s:^$$(pwd)/::")"; \
		# Remove any output files from the inputs since they can be \
		# regenerated: \
		for outfile in $$EXFILES; do \
			DEPFILES="$$(echo "$${DEPFILES}" | egrep -v "^$${outfile}")"; \
		done; \
		# Explicitly add the target PDF to the files to include. \
		DEPFILES="$$(echo "$${DEPFILES}"; echo "$${target}.pdf")"; \
		# Now remove all TeX-distribution input files (since we can assume \
		# that the compiler will have its own versions to use) and cache \
		# files created by LuaTex. \
		TEXEXCLUDE="$$(kpsewhich -var-value TEXMFROOT):$$(kpsewhich \
			-var-value TEXMFCACHE)"; \
		SAVEIFS="$$IFS"; \
		IFS=":"; \
		for sysdir in $$TEXEXCLUDE; do \
			DEPFILES="$$(echo "$${DEPFILES}" | egrep -v "^$${sysdir}")"; \
		done; \
		IFS="$$SAVEIFS"; \
		# Copy all the listed files to the temp directory. \
		for file in $$DEPFILES; do \
			# The first case looks for local files, in which case we want to \
			# preserve the relative layout. \
			if [[ ! "$${file}" =~ ^/ ]]; then \
				mkdir -p "$$(dirname "$${TMPDIR}/$(PROJECT)/$${file}")"; \
				cp -pL "$${file}" "$${TMPDIR}/$(PROJECT)/$${file}"; \
			# Anything coming from the user's local texmf tree should instead \
			# be copied to the archive root. \
			else \
				cp -pL "$${file}" "$${TMPDIR}/$(PROJECT)"; \
			fi; \
		done; \
		# Also include the explicit extra dependencies. \
		for file in $(ARCHIVE_EXTRA); do \
			# The first case looks for local files, in which case we want to \
			# preserve the relative layout. \
			if [[ ! "$${file}" =~ ^/ ]]; then \
				mkdir -p "$$(dirname "$${TMPDIR}/$(PROJECT)/$${file}")"; \
				cp -pL "$${file}" "$${TMPDIR}/$(PROJECT)/$${file}"; \
			# Any absolute paths should instead be copied to the archive root. \
			else \
				cp -pL "$${file}" "$${TMPDIR}/$(PROJECT)"; \
			fi; \
		done; \
		#echo -e "EXCLUDED FILES:\n$${EXFILES}\n"; \
		#echo -e "INCLUDED FILES:\n$${DEPFILES}\n"; \
	done; \
	# With everything collected, create the tar file and cleanup. \
	tar -C "$${TMPDIR}" -cz $(PROJECT) > $(PROJECT).tar.gz; \
	rm -fr "$${TMPDIR}";
