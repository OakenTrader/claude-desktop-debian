#===============================================================================
# KaTeX LaTeX rendering support: download KaTeX via npm, rewrite font URLs
# to use absolute CDN paths (so insertCSS resolves them correctly), copy
# runtime files into the asar, and copy the MutationObserver setup script.
#
# Sourced by: build.sh
# Sourced globals: source_dir, work_dir, app_staging_dir
# Modifies globals: (none)
#===============================================================================

install_katex() {
	section_header 'Installing KaTeX for LaTeX rendering'

	local katex_build_dir="$work_dir/katex-build"
	local katex_dest="$app_staging_dir/app.asar.contents/latex"

	mkdir -p "$katex_build_dir" || exit 1
	mkdir -p "$katex_dest" || exit 1

	# Install KaTeX from npm into a temporary build directory
	cd "$katex_build_dir" || exit 1
	echo '{"name":"katex-build","version":"1.0.0","private":true}' > package.json

	echo 'Installing KaTeX...'
	if ! npm install katex 2>&1; then
		echo "Error: 'npm install katex' failed." >&2
		echo 'LaTeX rendering will not be available.' >&2
		cd "$app_staging_dir" || exit 1
		section_footer 'KaTeX install (skipped — npm failed)'
		return
	fi

	local katex_npm="$katex_build_dir/node_modules/katex/dist"

	# Copy the three runtime files
	cp "$katex_npm/katex.min.js"          "$katex_dest/" || exit 1
	cp "$katex_npm/contrib/auto-render.min.js" "$katex_dest/" || exit 1

	# Rewrite font URLs in katex.min.css from relative to absolute CDN paths.
	# webContents.insertCSS has no base URL, so relative url(fonts/...) refs
	# would 404. Pointing them at jsDelivr means fonts load from CDN; if the
	# CSP blocks that, KaTeX still renders math with system fallback fonts.
	local katex_version
	katex_version=$(node -e "console.log(require('$katex_build_dir/node_modules/katex/package.json').version)")
	local cdn_base="https://cdn.jsdelivr.net/npm/katex@${katex_version}/dist"

	echo "  Rewriting font URLs to CDN base: $cdn_base/fonts/"
	sed "s|url(fonts/|url(${cdn_base}/fonts/|g" \
		"$katex_npm/katex.min.css" > "$katex_dest/katex.min.css" || exit 1

	echo "KaTeX ${katex_version} installed to app.asar.contents/latex/"
	cd "$app_staging_dir" || exit 1
	section_footer 'KaTeX installation'
}

patch_latex_render() {
	echo '##############################################################'
	echo 'Copying latex-render.js into asar...'

	local dest="$app_staging_dir/app.asar.contents/latex-render.js"

	if [[ ! -d "$app_staging_dir/app.asar.contents/latex" ]]; then
		echo '  latex/ directory not found — install_katex may have failed, skipping'
		echo '##############################################################'
		return
	fi

	cp "$source_dir/scripts/latex-render.js" "$dest" || exit 1
	echo "  Copied latex-render.js"
	echo '##############################################################'
}
