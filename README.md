# Quinn Asena — Personal Research Website

This is the source for [quinnasena.github.io](https://quinnasena.github.io/), built with [Quarto](https://quarto.org/).

## Structure

```
.
├── _quarto.yml               # Site-wide configuration (navbar, theme, metadata)
├── index.qmd                 # Homepage / about page
├── my-research.qmd           # Research listing page
├── my-research-posts/        # Individual research post files (.qmd) and images
├── resources-listing.qmd     # Resources listing page
├── resources-posts/          # Resources content and gallery template
├── styles.scss               # Custom styles (extends the Lux Bootswatch theme)
└── favicon.ico
```

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

## Adding a new research post

1. Create a new `.qmd` file in `my-research-posts/`, following the existing posts as a template.
2. Add the front matter fields: `title`, `date`, `image`, and `categories`.
3. Add the new file to the listing in `my-research.qmd`.
