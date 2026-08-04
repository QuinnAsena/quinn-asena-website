# Fonts

`source-serif-4-latin-600.woff2` — Source Serif 4, semibold, basic-latin subset (21 KB).

Used for all headings. Body text deliberately uses the OS system sans stack, so this is
the only font file the site ships.

Self-hosted rather than loaded from the Google Fonts CDN, which avoids a third-party
request on every page load and the associated EU data-protection question.

Only weight 600 is shipped because every heading level in the `lux` theme uses 600. If a
lighter weight is ever needed, add a separate `@font-face` block rather than relying on
the browser to synthesise one.

Wired up in `styles.scss`: `@font-face` in the rules section, `$headings-font-family` in
the defaults section. The `url()` is relative (`../../fonts/`) because the compiled CSS
lands in `_site/site_libs/bootstrap/`, and a relative path survives the site being served
from a subdirectory.

## Licence

Source Serif 4 is licensed under the SIL Open Font License 1.1. `OFL.txt` is the licence
text as published by Adobe, and the OFL requires it to be distributed alongside the font.

Source: <https://github.com/adobe-fonts/source-serif>

## Replacing the typeface

Download the latin-subset woff2 from Google Fonts using a browser user-agent (the API
serves unsubsetted TTF to clients it does not recognise as woff2-capable), drop it here,
then update the `@font-face` block and `$headings-font-family` in `styles.scss`.
