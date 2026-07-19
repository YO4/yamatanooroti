require 'yamatanooroti'
require 'json'

# tests intentionally redefine fetch_releases/capture2; silence the
# method-redefined warning that rake's -w emits on re-stubbing.
$VERBOSE = nil

class Yamatanooroti::TestWindowsTerminalResolve < Test::Unit::TestCase
  RELEASES_JSON = <<~JSON
    [
      {
        "tag_name": "v1.25.1322.0",
        "prerelease": true,
        "assets": [
          {
            "name": "Microsoft.WindowsTerminalPreview_1.25.1322.0_x64.zip",
            "browser_download_url": "https://example.com/1.25.1322.0.zip",
            "digest": "sha256:AAA"
          }
        ]
      },
      {
        "tag_name": "v1.25.1912.0",
        "prerelease": true,
        "assets": [
          {
            "name": "Microsoft.WindowsTerminalPreview_1.25.1912.0_x64.zip",
            "browser_download_url": "https://example.com/1.25.1912.0.zip",
            "digest": "sha256:BBB"
          }
        ]
      },
      {
        "tag_name": "v1.24.11911.0",
        "prerelease": false,
        "assets": [
          {
            "name": "Microsoft.WindowsTerminal_1.24.11911.0_x64.zip",
            "browser_download_url": "https://example.com/1.24.11911.0.zip",
            "digest": "sha256:CCC"
          }
        ]
      },
      {
        "tag_name": "v1.24.10921.0",
        "prerelease": false,
        "assets": [
          {
            "name": "Microsoft.WindowsTerminal_1.24.10921.0_x64.zip",
            "browser_download_url": "https://example.com/1.24.10921.0.zip"
          }
        ]
      }
    ]
  JSON

  def setup
    @orig = Yamatanooroti::Options::WindowsTerminal.method(:fetch_releases)
    Yamatanooroti::Options::WindowsTerminal.singleton_class.send(:define_method, :fetch_releases) do |**|
      JSON.parse(RELEASES_JSON)
    end
  end

  def teardown
    Yamatanooroti::Options::WindowsTerminal.singleton_class.send(:define_method, :fetch_releases, &@orig)
  end

  def test_resolve_by_prefix_takes_latest
    version = Yamatanooroti::Options::WindowsTerminal.interpret("1.25")
    assert_equal("1.25.1912.0", version)
    spec = Yamatanooroti::Options::WindowsTerminal.resolved[version]
    assert_equal("https://example.com/1.25.1912.0.zip", spec[:url])
    assert_equal("BBB", spec[:sha256])
  end

  def test_resolve_stable_takes_latest_non_prerelease
    version = Yamatanooroti::Options::WindowsTerminal.interpret(:stable)
    assert_equal("1.24.11911.0", version)
    spec = Yamatanooroti::Options::WindowsTerminal.resolved[version]
    assert_equal("CCC", spec[:sha256])
  end

  def test_resolve_preview_takes_latest_prerelease
    version = Yamatanooroti::Options::WindowsTerminal.interpret(:preview)
    assert_equal("1.25.1912.0", version)
  end

  def test_resolve_missing_sha256_is_nil
    version = Yamatanooroti::Options::WindowsTerminal.interpret("1.24.10921")
    spec = Yamatanooroti::Options::WindowsTerminal.resolved[version]
    assert_equal("1.24.10921.0", version)
    assert_nil(spec[:sha256])
  end

  def test_resolve_unknown_prefix_raises
    assert_raise(RuntimeError) do
      Yamatanooroti::Options::WindowsTerminal.interpret("9.99")
    end
  end

  def test_list_releases_summary
    m = Yamatanooroti::Options::WindowsTerminal
    releases = [
      { "tag_name" => "v1.25.3000.0", "prerelease" => true,
        "assets" => [{ "name" => "Microsoft.WindowsTerminalPreview_1.25.3000.0_x64.zip", "browser_download_url" => "u", "digest" => "sha256:A" }] },
      { "tag_name" => "v1.25.1000.0", "prerelease" => true,
        "assets" => [{ "name" => "Microsoft.WindowsTerminalPreview_1.25.1000.0_x64.zip", "browser_download_url" => "u", "digest" => "sha256:B" }] },
      { "tag_name" => "v1.24.2000.0", "prerelease" => false,
        "assets" => [{ "name" => "Microsoft.WindowsTerminal_1.24.2000.0_x64.zip", "browser_download_url" => "u", "digest" => "sha256:C" }] },
      { "tag_name" => "v1.23.9000.0", "prerelease" => false,
        "assets" => [{ "name" => "Microsoft.WindowsTerminal_1.23.9000.0_x64.zip", "browser_download_url" => "u", "digest" => "sha256:D" }] },
    ]
    m.singleton_class.send(:define_method, :fetch_releases) { |**| releases }
    begin
      out, _ = capture_stdout do
        m.list_releases(detail: false)
      end
      lines = out.lines.map(&:chomp)
      # latest preview (1.25.3000.0) and latest stable (1.24.2000.0) with type,
      # then the newest per n.mm minor not already shown (1.23.9000.0) without type.
      assert_equal(3, lines.size)
      assert(lines[0] == "1.25.3000.0\tpreview")
      assert(lines[1] == "1.24.2000.0\tstable")
      assert(lines[2] == "1.23.9000.0")
      # v1.25.1000.0 is NOT the newest in its minor -> omitted
      assert(lines.none? { |l| l.include?("1.25.1000.0") })
      # no url in summary
      assert(lines.none? { |l| l.include?("http") })
    ensure
      m.singleton_class.send(:define_method, :fetch_releases, &@orig)
    end
  end

  def test_list_releases_detail
    out, _ = capture_stdout do
      Yamatanooroti::Options::WindowsTerminal.list_releases(detail: true)
    end
    lines = out.lines.map(&:chomp)
    # all four releases appear, version + kind only (no url)
    assert_equal(4, lines.size)
    assert(lines.any? { |l| l.start_with?("1.25.1322.0\tpreview") })
    assert(lines.any? { |l| l.start_with?("1.24.10921.0\tstable") })
    assert(lines.none? { |l| l.include?("http") })
  end

  def test_fetch_releases_caches_under_cache_dir
    require 'tmpdir'
    require 'fileutils'
    require 'open3'
    require 'time'
    cache_dir = Dir.mktmpdir
    m = Yamatanooroti::Options::WindowsTerminal
    # restore the real fetch_releases (setup stubs it)
    m.singleton_class.send(:define_method, :fetch_releases, &@orig)
    begin
      Yamatanooroti::Options.instance_variable_set(:@terminal_workdir, cache_dir)
      fetched = 0
      # stub curl: write the body file (-o) and return "HTTP_CODE\nETag\nDate\nCache-Control"
      open3 = Open3.method(:capture2)
      Open3.singleton_class.send(:define_method, :capture2) do |*args|
        fetched += 1
        o_idx = args.index("-o")
        body_path = args[o_idx + 1]
        File.write(body_path, RELEASES_JSON)
        ["200\n\"etag-1\"\n#{Time.now.httpdate}\npublic, max-age=60",
         Struct.new(:success?).new(true)]
      end
      m.fetch_releases
      cache_path = File.join(m.cache_dir, "wt_releases.json")
      etag_path = File.join(m.cache_dir, "wt_releases.etag")
      meta_path = File.join(m.cache_dir, "wt_releases.meta")
      assert(File.exist?(cache_path), "cache file should be written")
      assert(File.exist?(etag_path), "etag sidecar should be written")
      assert(File.exist?(meta_path), "meta sidecar should be written")
      # second call: cache is fresh (max-age) -> no network at all
      m.fetch_releases
      assert_equal(1, fetched, "fresh cache should skip network")
      # third call after expiring the cache: conditional GET returns 304, reuse
      meta = JSON.parse(File.read(meta_path))
      meta["date"] = (Time.now - 120).httpdate # make it stale
      File.write(meta_path, meta.to_json)
      Open3.singleton_class.send(:define_method, :capture2) do |*args|
        fetched += 1
        o_idx = args.index("-o")
        body_path = args[o_idx + 1]
        File.write(body_path, "SHOULD-NOT-BE-USED")
        ["304\n\"etag-1\"\n#{Time.now.httpdate}\npublic, max-age=60",
         Struct.new(:success?).new(true)]
      end
      m.fetch_releases
      assert_equal(2, fetched)
      # cache body must be untouched (304 reuses it)
      assert_equal(JSON.parse(RELEASES_JSON), JSON.parse(File.read(cache_path)))
      # fourth call with force: ignores cache, unconditional 200 + new etag
      Open3.singleton_class.send(:define_method, :capture2) do |*args|
        fetched += 1
        o_idx = args.index("-o")
        body_path = args[o_idx + 1]
        File.write(body_path, RELEASES_JSON)
        ["200\n\"etag-2\"\n#{Time.now.httpdate}\npublic, max-age=60",
         Struct.new(:success?).new(true)]
      end
      m.fetch_releases(force: true)
      assert_equal(3, fetched)
      assert_equal("etag-2", File.read(etag_path).strip)
    ensure
      Open3.singleton_class.send(:define_method, :capture2, &open3) if open3
      FileUtils.remove_entry(cache_dir)
      Yamatanooroti::Options.instance_variable_set(:@terminal_workdir, nil)
    end
  end

  def test_per_page1_match_reuses_cache_without_full_fetch
    require 'tmpdir'
    require 'fileutils'
    require 'open3'
    require 'time'
    cache_dir = Dir.mktmpdir
    m = Yamatanooroti::Options::WindowsTerminal
    m.singleton_class.send(:define_method, :fetch_releases, &@orig)
    begin
      Yamatanooroti::Options.instance_variable_set(:@terminal_workdir, cache_dir)
      FileUtils.mkdir_p(m.cache_dir)
      # seed a cache (full list) + etag + stale meta so conditional GET runs
      File.write(File.join(m.cache_dir, "wt_releases.json"), RELEASES_JSON)
      File.write(File.join(m.cache_dir, "wt_releases.etag"), "etag-1")
      File.write(File.join(m.cache_dir, "wt_releases.meta"),
                 { "date" => (Time.now - 120).httpdate, "max_age" => 60 }.to_json)
      calls = []
      open3 = Open3.method(:capture2)
      Open3.singleton_class.send(:define_method, :capture2) do |*args|
        url = args.last
        calls << url
        o_idx = args.index("-o")
        body_path = args[o_idx + 1]
        if url.include?("&page=")
          File.write(body_path, RELEASES_JSON)
          ["200\n\"etag-2\"\n#{Time.now.httpdate}\npublic, max-age=60",
           Struct.new(:success?).new(true)]
        else
          # latest release matches the cached latest -> validation passes
          probe = JSON.parse(RELEASES_JSON)[0, 1].to_json
          File.write(body_path, probe)
          ["200\n\"etag-2\"\n#{Time.now.httpdate}\npublic, max-age=60",
           Struct.new(:success?).new(true)]
        end
      end
      m.fetch_releases
      # only the per_page=1 probe was sent; full list fetch was NOT needed
      assert_equal(1, calls.size, "matching per_page=1 should skip full fetch")
      assert(calls[0].include?("per_page=1"), "conditional GET should use per_page=1")
      # cache body unchanged (reused)
      assert_equal(JSON.parse(RELEASES_JSON),
                   JSON.parse(File.read(File.join(m.cache_dir, "wt_releases.json"))))
      assert_equal("etag-2", File.read(File.join(m.cache_dir, "wt_releases.etag")).strip)
    ensure
      Open3.singleton_class.send(:define_method, :capture2, &open3) if open3
      FileUtils.remove_entry(cache_dir)
      Yamatanooroti::Options.instance_variable_set(:@terminal_workdir, nil)
    end
  end

  def test_per_page1_mismatch_triggers_full_refetch
    require 'tmpdir'
    require 'fileutils'
    require 'open3'
    require 'time'
    cache_dir = Dir.mktmpdir
    m = Yamatanooroti::Options::WindowsTerminal
    m.singleton_class.send(:define_method, :fetch_releases, &@orig)
    begin
      Yamatanooroti::Options.instance_variable_set(:@terminal_workdir, cache_dir)
      FileUtils.mkdir_p(m.cache_dir)
      File.write(File.join(m.cache_dir, "wt_releases.json"), RELEASES_JSON)
      File.write(File.join(m.cache_dir, "wt_releases.etag"), "etag-1")
      File.write(File.join(m.cache_dir, "wt_releases.meta"),
                 { "date" => (Time.now - 120).httpdate, "max_age" => 60 }.to_json)
      calls = []
      open3 = Open3.method(:capture2)
      Open3.singleton_class.send(:define_method, :capture2) do |*args|
        url = args.last
        calls << url
        o_idx = args.index("-o")
        body_path = args[o_idx + 1]
        if url.include?("&page=")
          # full list re-fetch returns the original list
          File.write(body_path, RELEASES_JSON)
          ["200\n\"etag-2\"\n#{Time.now.httpdate}\npublic, max-age=60",
           Struct.new(:success?).new(true)]
        else
          # a NEW latest release (different tag_name) -> mismatch
          new_latest = JSON.parse(RELEASES_JSON)
          new_latest[0] = new_latest[0].merge("tag_name" => "v9.99.9999.0")
          File.write(body_path, new_latest[0, 1].to_json)
          ["200\n\"etag-2\"\n#{Time.now.httpdate}\npublic, max-age=60",
           Struct.new(:success?).new(true)]
        end
      end
      m.fetch_releases
      # per_page=1 probe + full list re-fetch
      assert_equal(2, calls.size, "mismatch should trigger full re-fetch")
      assert(calls[0].include?("per_page=1"), "first call should be per_page=1")
      assert(calls[1].include?("page="), "second call should be the full list")
      # cache fully rewritten with the full list
      assert_equal(JSON.parse(RELEASES_JSON),
                   JSON.parse(File.read(File.join(m.cache_dir, "wt_releases.json"))))
    ensure
      Open3.singleton_class.send(:define_method, :capture2, &open3) if open3
      FileUtils.remove_entry(cache_dir)
      Yamatanooroti::Options.instance_variable_set(:@terminal_workdir, nil)
    end
  end

  def test_fetch_releases_multi_page_merges_all_pages_on_refetch
    require 'tmpdir'
    require 'fileutils'
    require 'open3'
    require 'time'
    cache_dir = Dir.mktmpdir
    m = Yamatanooroti::Options::WindowsTerminal
    m.singleton_class.send(:define_method, :fetch_releases, &@orig)
    begin
      Yamatanooroti::Options.instance_variable_set(:@terminal_workdir, cache_dir)
      FileUtils.mkdir_p(m.cache_dir)
      File.write(File.join(m.cache_dir, "wt_releases.json"), RELEASES_JSON)
      File.write(File.join(m.cache_dir, "wt_releases.etag"), "etag-1")
      File.write(File.join(m.cache_dir, "wt_releases.meta"),
                 { "date" => (Time.now - 120).httpdate, "max_age" => 60 }.to_json)
      all_releases = JSON.parse(RELEASES_JSON)
      page_size = 2
      calls = []
      open3 = Open3.method(:capture2)
      Open3.singleton_class.send(:define_method, :capture2) do |*args|
        url = args.last
        calls << url
        o_idx = args.index("-o")
        body_path = args[o_idx + 1]
        if url.include?("&page=")
          # full fetch: honor ?per_page=&page=, slice the fixture
          md = url.match(/per_page=(\d+)&page=(\d+)/)
          ps = md[1].to_i
          pg = md[2].to_i
          slice = all_releases[(pg - 1) * ps, ps]
          File.write(body_path, slice.to_json)
          ["200\n\"etag-2\"\n#{Time.now.httpdate}\npublic, max-age=60",
           Struct.new(:success?).new(true)]
        else
          # mismatch: a newer latest release than the cached one
          probe = [all_releases[0].merge("tag_name" => "v9.99.9999.0")]
          File.write(body_path, probe.to_json)
          ["200\n\"etag-2\"\n#{Time.now.httpdate}\npublic, max-age=60",
           Struct.new(:success?).new(true)]
        end
      end
      # force a smaller PER_PAGE so the fixture spans multiple pages
      if m.const_defined?(:PER_PAGE, false)
        @prev_per_page = m.const_get(:PER_PAGE, false)
        m.send(:remove_const, :PER_PAGE)
      end
      m.const_set(:PER_PAGE, page_size)
      m.fetch_releases
      # 1 probe (mismatch) + page1 + page2 + page3 (empty trailing page)
      assert_equal(4, calls.size, "multi-page re-fetch should fetch all pages")
      assert(calls.any? { |u| u.include?("page=1") })
      assert(calls.any? { |u| u.include?("page=2") })
      assert(calls.any? { |u| u.include?("page=3") })
      # cache merged all pages
      cached = JSON.parse(File.read(File.join(m.cache_dir, "wt_releases.json")))
      assert_equal(all_releases.size, cached.size)
    ensure
      if m.const_defined?(:PER_PAGE, false)
        m.send(:remove_const, :PER_PAGE)
        m.const_set(:PER_PAGE, @prev_per_page) if @prev_per_page
      end
      Open3.singleton_class.send(:define_method, :capture2, &open3) if open3
      FileUtils.remove_entry(cache_dir)
      Yamatanooroti::Options.instance_variable_set(:@terminal_workdir, nil)
    end
  end



  private

  def capture_stdout
    require 'stringio'
    orig = $stdout
    $stdout = StringIO.new
    yield
    [$stdout.string, nil]
  ensure
    $stdout = orig
  end
end
