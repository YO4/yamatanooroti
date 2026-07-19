require 'win32/registry'
require 'tmpdir'
require 'fileutils'
require 'uri'
require 'digest/sha2'

module Yamatanooroti::WindowsConsoleSetup
  DelegationConsoleSetting = {
    conhost:  "{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}",
    terminal: "{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}",
    preview:  "{06EC847C-C0A5-46B8-92CB-7C92F6E35CD5}",
  }.freeze
  DelegationTerminalSetting = {
    conhost:  "{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}",
    terminal: "{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}",
    preview:  "{86633F1F-6454-40EC-89CE-DA4EBA977EE2}",
  }.freeze

  def self.wt_exe
    @wt_exe
  end

  def self.wt_wait
    0
  end

  begin
    Win32::Registry::HKEY_CURRENT_USER.open('Console') do |reg|
      @orig_conhost = reg['ForceV2']
    end
  rescue Win32::Registry::Error
  end
  begin
    Win32::Registry::HKEY_CURRENT_USER.open('Console\%%Startup') do |reg|
      @orig_console = reg['DelegationConsole']
      @orig_terminal = reg['DelegationTerminal']
    end
  rescue Win32::Registry::Error
  end

  Test::Unit.at_start do
    Yamatanooroti::Options.resolve_default!
    case Yamatanooroti.options.windows
    when :conhost
      puts "use conhost(classic, conhostV2) for windows console"
      Win32::Registry::HKEY_CURRENT_USER.open('Console', Win32::Registry::KEY_WRITE) do |reg|
        reg['ForceV2', Win32::Registry::REG_DWORD] = 1
      end
      Win32::Registry::HKEY_CURRENT_USER.open('Console\%%Startup', Win32::Registry::KEY_WRITE) do |reg|
        reg['DelegationConsole', Win32::Registry::REG_SZ] = DelegationConsoleSetting[:conhost]
        reg['DelegationTerminal', Win32::Registry::REG_SZ] = DelegationTerminalSetting[:conhost]
      end if @orig_console && @orig_terminal
    when :"legacy-conhost"
      puts "use conhost(legacy, conhostV1) for windows console"
      Win32::Registry::HKEY_CURRENT_USER.open('Console', Win32::Registry::KEY_WRITE) do |reg|
        reg['ForceV2', Win32::Registry::REG_DWORD] = 0
      end
      Win32::Registry::HKEY_CURRENT_USER.open('Console\%%Startup', Win32::Registry::KEY_WRITE) do |reg|
        reg['DelegationConsole', Win32::Registry::REG_SZ] = DelegationConsoleSetting[:conhost]
        reg['DelegationTerminal', Win32::Registry::REG_SZ] = DelegationTerminalSetting[:conhost]
      end if @orig_console && @orig_terminal
    when :canary
      @wt_exe = extract_terminal(prepare_terminal_canary)
    when :wt
      @wt_exe = prepare_terminal_wt
    else
      @wt_exe = extract_terminal(prepare_terminal_portable)
    end
    if @wt_exe
      Yamatanooroti::WindowsTerminalTerm.diagnose_size_capability
    end
  end

  Test::Unit.at_exit do
    Win32::Registry::HKEY_CURRENT_USER.open('Console', Win32::Registry::KEY_WRITE) do |reg|
      reg['ForceV2', Win32::Registry::REG_DWORD] = @orig_conhost
    end if @orig_conhost
    Win32::Registry::HKEY_CURRENT_USER.open('Console\%%Startup', Win32::Registry::KEY_WRITE) do |reg|
      reg['DelegationConsole', Win32::Registry::REG_SZ] = @orig_console
      reg['DelegationTerminal', Win32::Registry::REG_SZ] = @orig_terminal
    end if @orig_console && @orig_terminal
  end

  def self.tmpdir
    return @tmpdir if @tmpdir
    dir = nil
    if Yamatanooroti.options.terminal_workdir
      dir = Yamatanooroti.options.terminal_workdir
      FileUtils.mkdir_p(dir)
    else
      @tmpdir_t = Thread.new do
        Thread.current.abort_on_exception = true
        Dir.mktmpdir do |tmpdir|
          dir = tmpdir
          sleep
        ensure
          sleep 0.5 # wait for terminate windows terminal
        end
      end
      Thread.pass while dir == nil
    end
    return @tmpdir = dir
  end

  def self.extract_terminal(path)
    tar = File.join(ENV['SystemRoot'], "system32", "tar.exe")
    extract_dir = File.join(tmpdir, "wt")
    running_wt_exist = false
    if File.exist?(extract_dir)
      wt = Dir["**/OpenConsole.exe", base: extract_dir]
      running_wt_exist = wt.reduce(false) do |result, path|
        result ||= begin
          File.delete(File.join(extract_dir, path))
          false
        rescue SystemCallError
          true
        end
      end
      FileUtils.remove_entry(extract_dir) if !running_wt_exist
    end
    if !running_wt_exist
      FileUtils.mkdir_p(extract_dir)
      puts "extracting #{File.basename(path)}"
      system tar, "xf", path, "-C", extract_dir
      wt = Dir["**/wt.exe", base: extract_dir]
      raise "not found wt.exe. aborted." if wt.size < 1
      raise "found wt.exe #{wt.size} times unexpectedly. aborted." if wt.size > 1
      wt = File.join(extract_dir, wt[0])
      wt_dir = File.dirname(wt)
      portable_mark = File.join(wt_dir, ".portable")
      open(portable_mark, "w") { |f| f.puts } unless File.exist?(portable_mark)
      settings = File.join(wt_dir, "settings", "settings.json")
      FileUtils.mkdir_p(File.dirname(settings))
      open(settings, "wb") do |settings|
        settings.write <<~'JSON'
            {
                "defaultProfile": "{0caa0dad-35be-5f56-a8ff-afceeeaa6101}",
                "disableAnimations": true,
                "experimental.detectURLs": false,
                "minimizeToNotificationArea": false,
                "profiles": 
                {
                    "defaults": 
                    {
                        "bellStyle": "none",
                        "closeOnExit": "always",
                        "font": 
                        {
                            "size": 9
                        },
                        "padding": "0",
                        "scrollbarState": "always"
                    },
                    "list": 
                    [
                        {
                            "commandline": "%SystemRoot%\\System32\\cmd.exe",
                            "guid": "{0caa0dad-35be-5f56-a8ff-afceeeaa6101}",
                            "name": "cmd.exe"
                        }
                    ]
                },
                "showTabsInTitlebar": false,
                "tabWidthMode": "compact",
                "warning.confirmCloseAllTabs": false,
                "warning.largePaste": false,
                "warning.multiLinePaste": false
            }
        JSON
      end
      puts "use #{wt} for windows console"
    else
      puts "running Windows Terminal found."
      wt = Dir["**/wt.exe", base: extract_dir]
      raise "not found wt.exe. aborted." if wt.size < 1
      raise "found wt.exe #{wt.size} times unexpectedly. aborted." if wt.size > 1
      wt = File.join(extract_dir, wt[0])
      wt_dir = File.dirname(wt)
      puts "use existing #{wt} for windows console"
    end
    wt
  end

  def self.prepare_terminal_wt
    if Yamatanooroti.options.wt
      wt = Yamatanooroti.options.wt
      raise "not found #{wt}. aborted." unless File.exist?(wt)
    else
      wt = find_wt_on_path
      raise "not found wt.exe on PATH. aborted." unless wt
    end
    puts "use #{wt} for windows console"
    wt
  end

  def self.find_wt_on_path
    require 'open3'
    begin
      path, status = Open3.capture2("where", "wt.exe")
    rescue => e
      abort "failed to search wt.exe on PATH: #{e.message}"
    end
    path&.strip!
    return nil if path.to_s == "" || !status.success?
    path.each_line.first.strip
  end

  def self.prepare_terminal_canary
    dir = tmpdir
    header = `curl --head -sS -o #{tmpdir}/header -L -w "%{url_effective}\n%header{ETag}\n%header{Content-Length}\n%header{Last-Modified}" https://aka.ms/terminal-canary-zip-x64`
    url, etag, length, timestamp = *header.lines.map(&:chomp)
    puts "Windows Terminal canary #{timestamp}"
    name = File.basename(URI.parse(url).path)
    path = File.join(dir, "wt_dists", "canary", etag.delete('"'), name)
    if File.exist?(path)
      if File.size(path) == length.to_i
        puts "use existing #{path}"
        return path
      else
        FileUtils.remove_entry(path)
      end
    else
      if Dir.empty?(dir)
        puts "removing old canary zip"
        Dir.entries.each { |olddir| FileUtils.remove_entry(olddir) }
      end
    end
    FileUtils.mkdir_p(File.dirname(path))
    system "curl #{$stdin.isatty ? "" : "-sS "}-L -o #{path} https://aka.ms/terminal-canary-zip-x64"
    path
  end

  def self.prepare_terminal_portable
    releases = Yamatanooroti::WindowsConsoleSetup::WindowsTerminal.resolved
    spec = releases[Yamatanooroti.options.windows.to_s]
    raise "not resolved windows terminal version: #{Yamatanooroti.options.windows}" unless spec
    url = spec[:url]
    sha256 = spec[:sha256]
    dir = tmpdir
    name = File.basename(URI.parse(url).path)
    path = File.join(dir, "wt_dists", Yamatanooroti.options.windows, name)
    if File.exist?(path)
      if !sha256 || Digest::SHA256.new.file(path).hexdigest.upcase == sha256
        puts "use existing #{path}"
        return path
      else
        FileUtils.remove_entry(path)
      end
    end
    FileUtils.mkdir_p(File.dirname(path))
    system "curl #{$stdin.isatty ? "" : "-sS "}-L -o #{path} #{url}"
    if sha256
      raise "not match windows terminal distribution zip sha256" unless Digest::SHA256.new.file(path).hexdigest.upcase == sha256
    end
    path
  end

  module WindowsTerminal
    RELEASES_API = "https://api.github.com/repos/microsoft/terminal/releases"
    # resolved version -> { url:, sha256: }  (sha256 may be nil)
    @resolved = {}
    class << self
      attr_reader :resolved
    end

    CACHE_FILENAME = "wt_releases.json"
    CACHE_ETAG_FILENAME = "wt_releases.etag"
    CACHE_META_FILENAME = "wt_releases.meta"

    # directory to cache the releases JSON. uses --wt-dir if specified.
    def self.cache_dir
      dir = Yamatanooroti.options.terminal_workdir
      return nil unless dir
      File.join(dir, "wt_dists")
    end

    # read the cached etag (without surrounding quotes) or nil.
    def self.read_cached_etag(cache_dir)
      path = File.join(cache_dir, CACHE_ETAG_FILENAME)
      return nil unless File.exist?(path)
      File.read(path).strip.delete('"')
    rescue
      nil
    end

    # write the cached etag (without surrounding quotes).
    def self.write_cached_etag(cache_dir, etag)
      require 'fileutils'
      FileUtils.mkdir_p(cache_dir)
      File.write(File.join(cache_dir, CACHE_ETAG_FILENAME), etag.to_s.delete('"'))
    rescue
      nil
    end

    # read cached meta { date:, max_age: } or nil.
    def self.read_cached_meta(cache_dir)
      path = File.join(cache_dir, CACHE_META_FILENAME)
      return nil unless File.exist?(path)
      require 'json'
      JSON.parse(File.read(path))
    rescue
      nil
    end

    # is the cached response still fresh per Cache-Control max-age?
    def self.cache_fresh?(meta)
      return false unless meta && meta["date"] && meta["max_age"]
      require 'time'
      fetched = Time.httpdate(meta["date"]) rescue nil
      return false unless fetched
      (fetched + meta["max_age"].to_i) > Time.now
    rescue
      false
    end

    # number of releases fetched per API page
    PER_PAGE = 100

    # fetch a single page and return [http_code, body, etag, date, cache_control].
    # overridable for testing via Open3.capture2 stub.
    def self.fetch_page(url, etag: nil)
      require 'open3'
      require 'tmpdir'
      Dir.mktmpdir do |tmp|
        body_path = File.join(tmp, "body")
        cmd = ["curl", "-sS", "-L"]
        cmd += ["-H", "If-None-Match: #{etag}"] if etag
        cmd += ["-o", body_path,
                "-w", "%{http_code}\n%header{ETag}\n%header{Date}\n%header{Cache-Control}",
                url]
        out, status = Open3.capture2(*cmd)
        raise "failed to fetch windows terminal releases: #{RELEASES_API}" unless status.success?
        code, resp_etag, resp_date, resp_cc = out.lines.map(&:chomp)
        [code.to_i, File.read(body_path), resp_etag, resp_date, resp_cc]
      end
    end

    # fetch the releases JSON with HTTP cache validation.
    # - if the cached response is still fresh (Cache-Control max-age), reuse
    #   it without any network access.
    # - otherwise, validate page 1 with If-None-Match (ETag) + ?per_page=1
    #   by comparing the latest tag_name:
    #     * 304 or matching tag_name -> reuse the cache (incl. all pages).
    #     * mismatch -> re-fetch the full list across all pages and update
    #       the cache (page 2+ are fetched together with page 1 only then).
    # - force: true ignores the cache entirely.
    # overridable for testing.
    def self.fetch_releases(force: false, cache_dir: nil)
      cache_dir ||= self.cache_dir
      require 'json'

      cached_body = nil
      if cache_dir && !force
        cache_path = File.join(cache_dir, CACHE_FILENAME)
        if File.exist?(cache_path)
          begin
            cached_body = File.read(cache_path)
            JSON.parse(cached_body) # validate
          rescue
            cached_body = nil
          end
        end
      end

      # fresh cache: no network needed at all (all pages reused)
      if cached_body && !force && cache_fresh?(read_cached_meta(cache_dir))
        return JSON.parse(cached_body)
      end

      etag = (cache_dir && cached_body && !force) ? read_cached_etag(cache_dir) : nil

      if etag
        # validate only page 1 with per_page=1
        code, body, resp_etag, resp_date, resp_cc = fetch_page("#{RELEASES_API}?per_page=1", etag: etag)
        if code == 304 && cached_body
          return JSON.parse(cached_body)
        end
        raise "unexpected HTTP status #{code} from #{RELEASES_API}" unless code == 200

        probe = JSON.parse(body)
        cached_latest = (cached_body && !cached_body.empty?) ? JSON.parse(cached_body)[0] : nil
        if probe[0] && cached_latest &&
           probe[0]["tag_name"].to_s == cached_latest["tag_name"].to_s
          # cache is still up to date; refresh etag/meta only, reuse all pages
          write_cached_etag(cache_dir, resp_etag) if resp_etag && !resp_etag.empty?
          write_cached_meta(cache_dir, resp_date, resp_cc)
          return JSON.parse(cached_body)
        end
        # mismatch (new release): re-fetch the full list below
      end

      # full list re-fetch across all pages
      all = []
      page = 1
      loop do
        code, body, resp_etag, resp_date, resp_cc = fetch_page("#{RELEASES_API}?per_page=#{PER_PAGE}&page=#{page}")
        raise "unexpected HTTP status #{code} from #{RELEASES_API}" unless code == 200
        page_releases = JSON.parse(body)
        all.concat(page_releases)
        break if page_releases.size < PER_PAGE
        page += 1
      end
      if cache_dir
        require 'fileutils'
        FileUtils.mkdir_p(cache_dir)
        File.write(File.join(cache_dir, CACHE_FILENAME), all.to_json)
        write_cached_etag(cache_dir, resp_etag) if resp_etag && !resp_etag.empty?
        write_cached_meta(cache_dir, resp_date, resp_cc)
      end
      all
    end

    # write the cached meta { date:, max_age: }.
    def self.write_cached_meta(cache_dir, date, cache_control)
      require 'json'
      require 'fileutils'
      meta = { "date" => date, "max_age" => nil }
      if cache_control && cache_control =~ /max-age=(\d+)/
        meta["max_age"] = $1.to_i
      end
      File.write(File.join(cache_dir, CACHE_META_FILENAME), meta.to_json)
    rescue
      nil
    end

    # parse "v1.25.1912.0" -> [1, 25, 1912, 0] for comparison
    def self.parse_version(tag)
      tag.to_s.sub(/\Av/, "").split(".").map(&:to_i)
    rescue
      []
    end

    # select the x64 zip asset for a release
    def self.pick_asset(release)
      release["assets"].find { |a| a["name"] =~ /Microsoft\.WindowsTerminal(Preview)?_.*_x64\.zip\z/ }
    end

    # print the available windows terminal releases.
    # detail: false -> the latest preview and the latest stable (with type),
    #   followed by all remaining versions (version only, no type).
    # detail: true  -> all releases (version and type only, no URL).
    def self.list_releases(detail: false, force: false, cache_dir: nil)
      releases = fetch_releases(force: force)
      ordered = releases.sort_by { |r| parse_version(r["tag_name"]) }.reverse
      if detail
        ordered.each do |r|
          next unless pick_asset(r)
          version = r["tag_name"].to_s.sub(/\Av/, "")
          kind = r["prerelease"] ? "preview" : "stable"
          puts "#{version}\t#{kind}"
        end
      else
        # latest preview and latest stable with type, then the latest one
        # per n.mm (minor) version, listed without a type.
        latest = { preview: nil, stable: nil }
        ordered.each do |r|
          next unless pick_asset(r)
          kind = r["prerelease"] ? :preview : :stable
          cur = latest[kind]
          if cur.nil? || (parse_version(cur["tag_name"]) <=> parse_version(r["tag_name"])) < 0
            latest[kind] = r
          end
        end
        shown = {}
        [:preview, :stable].each do |kind|
          r = latest[kind]
          next unless r
          version = r["tag_name"].to_s.sub(/\Av/, "")
          puts "#{version}\t#{kind}"
          shown[r["tag_name"]] = true
        end
        newest_per_minor = {}
        ordered.each do |r|
          next unless pick_asset(r)
          v = parse_version(r["tag_name"])
          next if v.empty?
          key = v[0..1]
          cur = newest_per_minor[key]
          if cur.nil? || (parse_version(cur["tag_name"]) <=> v) < 0
            newest_per_minor[key] = r
          end
        end
        newest_per_minor.sort_by { |k, r| parse_version(r["tag_name"]) }.reverse_each do |_, r|
          next if shown[r["tag_name"]]
          puts r["tag_name"].to_s.sub(/\Av/, "")
        end
      end
    end

    # resolve a release by version prefix (e.g. "1.22") taking the latest.
    # spec: returns { version:, url:, sha256: } or nil when no match.
    def self.resolve_by_prefix(prefix)
      releases = fetch_releases(force: Yamatanooroti.options.wt_refresh_cache)
      matched = releases.select do |r|
        tag = r["tag_name"].to_s
        tag.start_with?("v#{prefix}")
      end
      return nil if matched.empty?
      release = matched.max_by { |r| parse_version(r["tag_name"]) }
      asset = pick_asset(release)
      return nil unless asset
      version = release["tag_name"].to_s.sub(/\Av/, "")
      sha256 = asset["digest"].to_s[/sha256:(\h+)/i, 1]
      sha256 = sha256.upcase if sha256
      {
        version: version,
        url: asset["browser_download_url"],
        sha256: sha256,
      }
    end

    # resolve the latest stable (non-prerelease) or preview (prerelease).
    def self.resolve_latest(prerelease)
      releases = fetch_releases(force: Yamatanooroti.options.wt_refresh_cache)
      candidates = releases.select { |r| r["prerelease"] == prerelease }
      return nil if candidates.empty?
      release = candidates.max_by { |r| parse_version(r["tag_name"]) }
      asset = pick_asset(release)
      return nil unless asset
      version = release["tag_name"].to_s.sub(/\Av/, "")
      sha256 = asset["digest"].to_s[/sha256:(\h+)/i, 1]
      sha256 = sha256.upcase if sha256
      {
        version: version,
        url: asset["browser_download_url"],
        sha256: sha256,
      }
    end

    # resolve a windows terminal spec from the --windows= value.
    # returns the resolved version string key, caching the spec.
    def self.interpret(name)
      case name
      when :canary
        return name
      when :stable
        spec = resolve_latest(false)
        raise "failed to resolve windows terminal stable release" unless spec
        @resolved[spec[:version]] = spec
        return spec[:version]
      when :preview
        spec = resolve_latest(true)
        raise "failed to resolve windows terminal preview release" unless spec
        @resolved[spec[:version]] = spec
        return spec[:version]
      else
        key = name.to_s
        if /\A\d+\.\d+(\.\d+)?\z/ =~ key
          spec = resolve_by_prefix(key)
          raise "no windows terminal release matches version prefix `#{key}'" unless spec
          @resolved[spec[:version]] = spec
          return spec[:version]
        end
        # exact resolved version key (e.g. re-entrant)
        if @resolved.key?(key)
          return key
        end
        raise "unknown windows terminal version: #{key}"
      end
    end
  end
end
