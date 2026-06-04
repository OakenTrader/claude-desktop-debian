// __claude_latex_render — marker for patch idempotency check
//
// Inline math ($...$) rendering for claude.ai's BrowserView.
// auto-render.min.js has been injected by frame-fix-wrapper.js before
// this script runs, replacing claude.ai's display-only renderMathInElement
// with a version that also handles $...$ inline delimiters.
//
// Uses requestIdleCallback so scans never run during scroll or animation.
// Set CLAUDE_LATEX=0 to disable entirely (see frame-fix-wrapper.js).

(function () {
  if (window.__claudeLatexInstalled) return;
  window.__claudeLatexInstalled = true;

  var OPTIONS = {
    delimiters: [
      { left: '$$',  right: '$$',  display: true  },
      { left: '\\[', right: '\\]', display: true  },
      { left: '$',   right: '$',   display: false },
      { left: '\\(', right: '\\)', display: false },
    ],
    throwOnError: false,
    ignoredTags: ['script', 'noscript', 'style', 'textarea', 'pre', 'code', 'kbd', 'samp'],
    ignoredClasses: ['no-latex'],
  };

  function scan() {
    try {
      window.renderMathInElement(document.body, OPTIONS);
    } catch (e) { /* ignore */ }
    window.requestIdleCallback(scan, { timeout: 3000 });
  }

  var attempts = 0;
  function start() {
    if (typeof window.renderMathInElement === 'function') {
      window.requestIdleCallback(scan, { timeout: 500 });
      console.log('[LaTeX Render] inline math scanner started');
      return;
    }
    if (++attempts < 10) setTimeout(start, 200);
  }
  start();
})();
