require "csv"
require "json"
require "net/http"
require "time"
require "uri"

# Fetches a pull request from the GitHub REST API and writes the fields we
# care about (author, merger, additions/deletions, timings) to a CSV file.
class PrFetcher
  API_ROOT = "https://api.github.com".freeze

  HEADERS = %w[
    pr_number
    author_login author_id author_name author_email author_company
    author_location author_public_repos author_created_at author_url
    merged_by_login merged_by_id merged_by_name merged_by_email merged_by_company
    merged_by_location merged_by_public_repos merged_by_created_at merged_by_url
    additions deletions
    created_at merged_at time_to_merge_seconds time_to_merge
  ].freeze

  class Error < StandardError; end

  def initialize(repo:, number:, token: nil)
    @repo = repo
    @number = number
    @token = token
    @user_cache = {}
  end

  def row
    pr = get("/repos/#{@repo}/pulls/#{@number}")
    raise Error, "PR ##{@number} has not been merged" unless pr["merged_at"]

    self.class.build_row(pr, user(pr["user"]["login"]), user(pr["merged_by"]["login"]))
  end

  def write_csv(path)
    CSV.open(path, "w") do |csv|
      csv << HEADERS
      csv << row
    end
    path
  end

  # Pure transformation, kept separate from HTTP so it can be tested offline.
  def self.build_row(pr, author, merger)
    created = Time.parse(pr["created_at"])
    merged = Time.parse(pr["merged_at"])
    seconds = (merged - created).to_i

    [pr["number"]] + user_fields(author) + user_fields(merger) + [
      pr["additions"], pr["deletions"],
      created.utc.iso8601, merged.utc.iso8601,
      seconds, format_duration(seconds)
    ]
  end

  def self.user_fields(u)
    [u["login"], u["id"], u["name"], u["email"], u["company"],
     u["location"], u["public_repos"], u["created_at"], u["html_url"]]
  end

  def self.format_duration(total)
    h, rem = total.divmod(3600)
    m, s = rem.divmod(60)
    format("%02d:%02d:%02d", h, m, s)
  end

  private

  def user(login)
    @user_cache[login] ||= get("/users/#{login}")
  end

  def get(path)
    uri = URI("#{API_ROOT}#{path}")
    req = Net::HTTP::Get.new(uri)
    req["Accept"] = "application/vnd.github+json"
    req["User-Agent"] = "dxInterview-pr-fetcher"
    req["Authorization"] = "Bearer #{@token}" if @token

    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
    unless res.is_a?(Net::HTTPSuccess)
      hint = res.code == "404" && !@token ? " (private repo? set GITHUB_TOKEN)" : ""
      raise Error, "GET #{path} failed: #{res.code} #{res.message}#{hint}"
    end
    JSON.parse(res.body)
  end
end
