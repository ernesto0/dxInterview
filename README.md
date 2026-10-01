# dxInterview

A small project built for a technical assessment. It demonstrates a basic API integration, developed through a normal Git workflow (feature branches, commits, and pull requests).

## Overview

A Ruby script that retrieves a pull request from the GitHub REST API and stores the details locally in a CSV file. By default it fetches PR #1 of this repository.

Each CSV row contains:

- **Author** of the PR (GitHub user details: login, id, name, email, company, location, public repos, account creation date, profile URL).
- **Merger** of the PR (same fields; in this exercise it is the same user as the author).
- **PR details:** additions, deletions, created timestamp, merged timestamp, and the time between creation and merge (both in seconds and as `HH:MM:SS`).

Endpoints used:

- `GET /repos/:owner/:repo/pulls/:number`
- `GET /users/:login`

Fields a user has not filled in on their GitHub profile (e.g. name, email) are left blank.

## Getting Started

### Prerequisites

- Ruby 2.6 or newer
- Git

No gems are required; the script uses only the Ruby standard library.

### Installation

```bash
git clone https://github.com/ernesto0/dxInterview.git
cd dxInterview
```

### Configuration

The repository is public, so no credentials are needed. Optionally set `GITHUB_TOKEN` to raise the API rate limit or to read private repositories:

```bash
export GITHUB_TOKEN=<your token>
```

### Running

```bash
bin/fetch_pr [owner/repo] [pr_number] [output.csv]
```

All arguments are optional and default to `ernesto0/dxInterview 1 pr_1.csv`.

```bash
bin/fetch_pr                      # writes pr_1.csv
bin/fetch_pr ernesto0/dxInterview 1 out.csv
```

### Testing

```bash
ruby test/pr_fetcher_test.rb
```

The tests cover the row-building and duration logic without making network calls.

## Project Structure

```
dxInterview/
├── bin/fetch_pr               # command-line entry point
├── lib/pr_fetcher.rb          # API client + CSV writer
├── test/pr_fetcher_test.rb    # unit tests
├── pr_1.csv                   # sample output
└── README.md
```

## Workflow

1. Create a feature branch from `main`.
2. Make small, focused commits.
3. Open a pull request into `main` for review.

## Notes / Design Decisions

- **Standard library only** (`net/http`, `json`, `csv`, `time`) to keep setup to zero dependencies.
- **Separate user lookup:** the PR payload only includes a trimmed user object, so full user details come from `/users/:login`. Lookups are cached, so the author and merger (same user here) cost one request.
- **Pure transformation:** `PrFetcher.build_row` takes parsed JSON and returns the row, which keeps the logic testable without HTTP.
- **Unmerged PRs** raise a clear error since there is no merge data to record.
- **Errors** from the API surface the HTTP status, with a hint to set `GITHUB_TOKEN` on a 404.

## Future Improvements

- Support fetching multiple PRs and appending rows to one CSV.
- Retry with backoff and handle rate-limit responses.
- Add integration tests using recorded HTTP responses (e.g. WebMock/VCR).
- Package as a gem with a Gemfile and CI to run the tests.
