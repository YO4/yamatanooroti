require 'yamatanooroti'

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
    Yamatanooroti::Options::WindowsTerminal.singleton_class.send(:define_method, :fetch_releases) do
      require 'json'
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
end
