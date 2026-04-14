# Quinn Asena — Personal Research Website

This is the source for my website [quinnasena.github.io](https://quinnasena.github.io/quinn-asena-website/), built with [Quarto](https://quarto.org/).

## Building locally

1. [Install Quarto](https://quarto.org/docs/get-started/) (v1.4 or later recommended).
2. Clone this repository.
3. Preview the site with live reload:

   ```bash
   quarto preview
   ```

4. Or render the full site to the `_site/` directory:

   ```bash
   quarto render
   ```

## Deployment

The site is deployed to [GitHub Pages](https://pages.github.com/) via the `gh-pages` branch.

A GitHub Actions workflow (`.github/workflows/publish.yml`) automatically renders and publishes the site on every push to `main`. To publish manually:

```bash
quarto publish gh-pages
```
