# ORPI — Open Register of Pecuniary Interests

ORPI is a Ruby on Rails 8 application that ingests the Register of Pecuniary and Other Specified Interests and publishes a searchable interface showing MPs, their roles, and declared interests. It also includes tooling to extract structured data from source PDFs using RubyLLM and imports it into the database.

## Features

- **Browse political entities:** Index and detail pages for MPs in `New Zealand Parliament`.
- **Interests by category:** Interests stored against 14 standard categories via `InterestCategory`.
- **Search and filtering:** Interest and political entity listing endpoints with filters.
- **Image enrichment:** Fetch profile images for MPs from Wikimedia using `WikimediaImageService` tasks.
- **Embeddings and similarity:** Uses `sqlite-vec` and `neighbor` gems to support vector search (see `EmbeddingService`).
- **PWA bits:** Manifest and service worker endpoints are present.

## Tech stack

- Ruby 3.4.x (Dockerfile uses `ARG RUBY_VERSION=3.4.3`)
- Rails 8.0.x (`~> 8.0.2.1`)
- SQLite (application and vector extensions via `sqlite3` and `sqlite-vec`)
- Tailwind CSS (via `tailwindcss-rails` and `cssbundling-rails`)
- Turbo/Stimulus (Hotwire)
- RubyLLM (Gemini/Anthropic) for PDF → JSONL extraction
- Solid Queue/Cache/Cable
- Puma + Thruster

## Getting started (local dev)

1. Prerequisites

   - Ruby 3.4.x and Bundler, Node.js (to build JS/CSS), SQLite installed locally
   - Or use Docker for production-like builds
   - Environment variables for RubyLLM if you intend to run PDF serialization: `GEMINI_API_KEY`, `ANTHROPIC_API_KEY`

2. Install dependencies

```bash
bundle install
npm install
```

3. Database setup

```bash
bin/rails db:setup
```

This creates the SQLite database and loads schema. Seed data for categories/jurisdictions lives in `db/seeds/` and is loaded by `db:seed`.

4. Start the app (Procfile.dev)
   In one terminal:

```bash
bin/rails server
```

In others:

```bash
npm run build -- --watch
npm run build:css
```

Alternatively, use the included process file:

```bash
bin/dev
```

`Procfile.dev` defines: web, js, css.

## Environment configuration

RubyLLM initializer (`config/initializers/ruby_llm.rb`) requires:

- `GEMINI_API_KEY`
- `ANTHROPIC_API_KEY`
  Optional:
- `DEFAULT_CHAT_MODEL` (defaults to `gemini-2.5-flash`)
  When building assets in Docker, dummy keys are injected only for compile-time: `SECRET_KEY_BASE_DUMMY=1 GEMINI_API_KEY=1 ANTHROPIC_API_KEY=1`.

## Data model overview

- `PoliticalEntity` — MP/individual.
- `Jurisdiction` — currently `New Zealand Parliament`.
- `PoliticalEntityJurisdiction` — joins entity to jurisdiction with `role`, `electorate`, `affiliation`.
- `InterestCategory` — the 14 categories (1–14).
- `Interest` — individual interest records, linked to `PoliticalEntityJurisdiction` and `InterestCategory`, includes `source_page_numbers` and `source`.
- `Source` — describes the register/year.

## Importing data

There are two steps: (1) serialize PDF → JSONL with RubyLLM, then (2) import JSONL into the database.

1. Serialize a source PDF into JSONL
   Task: `import:serialize`

```bash
rake import:serialize[path/to/2025.pdf]
```

Options via env:

- `KEEP=true` — keep per-individual intermediate files to skip reprocessing
- `DELAY=0` — seconds to sleep between LLM requests
  Outputs:
- `2025_lookup.json` — name → page numbers map
- `2025.jsonl` — one JSON object per individual, including sections and page numbers

2. Import the JSONL into the DB
   Task: `import:json`

```bash
rake import:json[2025.jsonl]
# or
JSONL_FILE=2025.jsonl rake import:json
```

What it does:

- Ensures a `Source` record: "2025 Register of Pecuniary and Other Specified Interests"
- Ensures a `Jurisdiction`: "New Zealand Parliament"
- Creates/links `PoliticalEntity`, `PoliticalEntityJurisdiction`
- Creates `Interest` rows under the correct `InterestCategory`
- Prints import counts and skips

## Enriching images

Fetch images for all entities from Wikimedia:

```bash
rake political_entities:fetch_images
```

Fetch for a specific entity:

```bash
rake "political_entities:fetch_image[Full Name]"
```

List metadata for attached images:

```bash
rake political_entities:show_image_metadata
```

## Running tests

```bash
bin/rails test
```

System tests require a browser driver (Selenium/Chromium) if present.

## Routes of interest

- `GET /` — Home
- `GET /interests` — Interests index and filters
- `GET /political-entities` — Political entities index
- `GET /political-entities/:id` — Political entity detail
- `GET /political-entities/:id/export` — Per-entity export
- `GET /comparison` — Comparison page
- `GET /manifest` and `GET /service-worker` — PWA endpoints

## Production build and run (Docker)

This repository includes a multi-stage Dockerfile intended for production images.

Build:

```bash
docker build -t orpi .
```

Run (requires Rails master key and DB volume if you want persistence):

```bash
docker run -d \
  -p 80:80 \
  -e GEMINI_API_KEY=(your API key) \
  -e ANTHROPIC_API_KEY=(your API key) \
  -e RAILS_SECRET_KEY_BASE=(your secret key) \
  --name orpi orpi
```

The container uses `/rails/bin/docker-entrypoint` to prepare the database and starts via Thruster.

## Configuration notes

- Vector search requires `sqlite-vec` (installed via gem) and uses `neighbor` in code. Ensure your SQLite has the extension available in production.
- Asset compilation uses Propshaft, JS bundling, and Tailwind. For production, assets are precompiled during the image build.

## Troubleshooting

- "GEMINI_API_KEY/ANTHROPIC_API_KEY missing": set them in your shell or `.env` when running `import:serialize`.
- Import category warnings: if a section key does not match an `InterestCategory.key`, the importer prints a warning and skips those items.
- If images fail to fetch, the Wikimedia service may not have a suitable page; try a different name variant.
