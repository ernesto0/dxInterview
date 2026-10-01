require "minitest/autorun"
require_relative "../lib/pr_fetcher"

class PrFetcherTest < Minitest::Test
  USER = {
    "login" => "octo", "id" => 1, "name" => "Octo Cat", "email" => nil,
    "company" => "GitHub", "location" => "SF", "public_repos" => 3,
    "created_at" => "2020-01-01T00:00:00Z", "html_url" => "https://github.com/octo"
  }.freeze

  PR = {
    "number" => 7, "additions" => 10, "deletions" => 2,
    "created_at" => "2026-10-01T14:00:00Z", "merged_at" => "2026-10-01T15:01:05Z"
  }.freeze

  def test_build_row_matches_headers_and_computes_duration
    row = PrFetcher.build_row(PR, USER, USER)

    assert_equal PrFetcher::HEADERS.size, row.size
    data = PrFetcher::HEADERS.zip(row).to_h
    assert_equal 10, data["additions"]
    assert_equal 2, data["deletions"]
    assert_equal 3665, data["time_to_merge_seconds"]
    assert_equal "01:01:05", data["time_to_merge"]
    assert_equal "octo", data["merged_by_login"]
  end
end
