# Rich Preview Microservice

Elixir/Phoenix service for generating link previews with WhatsApp-style metadata extraction.

## Features
- Open Graph/Twitter metadata parsing
- Concurrent request handling
- Auto-scale across CPU cores

## Requirements
- Elixir 1.15+
- Erlang OTP 26+

## Setup

1. Install dependencies:
```bash
mix deps.get
```

2. Start server:
```bash
mix phx.server
```

## Usage

```bash
curl "http://localhost:4000/api/v1/preview?url=https://example.com"
```

Sample Response:
```json
{
  "title": "Example Domain",
  "description": "This domain is for use in illustrative examples...",
  "image": "https://example.com/og-image.jpg",
  "url": "https://example.com"
}
```

## Deployment

1. Production build:
```bash
MIX_ENV=prod mix release
```

2. Run with maximum CPU utilization:
```bash
ERL_FLAGS="+S 4:4" _build/prod/rel/rich_preview/bin/rich_preview start
```

## Docker

```dockerfile
FROM elixir:1.15

WORKDIR /app
COPY . .

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix release

CMD ["_build/prod/rel/rich_preview/bin/rich_preview", "start"]
```

## For Ruby Developers

- Processes ≠ Threads: 1MB memory footprint vs 10KB
- `Task.async` ≈ Concurrent::Promise but more lightweight
- Pattern matching ≈ case/when with type checking

