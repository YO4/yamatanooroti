class Yamatanooroti
  module Options
    @list_wt_releases = nil
    class << self
      attr_accessor :list_wt_releases
    end

    # if --list-wt-releases was requested, print the list and exit.
    # deferred until after all options (including --wt-dir) are parsed so the
    # cache directory is known.
    def self.run_list_if_requested
      return unless @list_wt_releases
      WindowsTerminal.list_releases(detail: @list_wt_releases == :all,
                                    force: Yamatanooroti.options.wt_refresh_cache)
      exit
    end

    # register the deferred list action once test/unit is available.
    def self.install_list_hook
      return if @list_hook_installed
      Test::Unit.at_start do
        run_list_if_requested
      end
      @list_hook_installed = true
    end

    options = [
      :default_wait,
      :default_timeout,

      # windows console selection
      :windows,

      # true if conhost(classic) or conhost(legacy)
      :conhost,

      # true if windows terminal
      :terminal,

      # windows terminal download/extract dir
      :terminal_workdir,

      # force re-fetch windows terminal releases refreshing the cache
      :wt_refresh_cache,

      # windows terminal executable path (--wt=PATH)
      :wt,

      # show console window on windows
      :show_console,

      # conditional close console window on windows
      :close_console,
    ]
    self.singleton_class.instance_eval do
      attr_reader(*options)
    end

    Accessor = Module.new do |mod|
      options.each do |name|
        mod.define_method name do
          Yamatanooroti::Options.public_send(name)
        end
      end
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

    CONHOST_TYPES = [:conhost, :"legacy-conhost"]
    WT_TYPE = [:wt]
    TERMINAL_TYPES = [:stable, :preview, :canary]
    TERMINAL_VERSION_RE = /\A\d+\.\d+(\.\d+)?\z/
    CLOSE_WHEN = [:always, :pass, :never]

    def self.parse_common(autorunner, o)
      install_list_hook
      @default_wait = 0.01
      @default_timeout = 2.0
      @windows = Yamatanooroti.win? ? :conhost : nil
      @conhost = false
      @terminal = false
      @terminal_workdir = nil
      @wt_refresh_cache = false
      @wt = nil
      @show_console = nil
      @close_console = :always

      o.on_tail("yamatanooroti options")
      o.on_tail("--wait=#{@default_wait}", Float,
                "Specify yamatanooroti wait time in seconds.") do |seconds|
        @default_wait = seconds
      end

      o.on_tail("--timeout=#{@default_timeout}", Float,
                "Specify yamatanooroti timeout in seconds.") do |seconds|
        @default_timeout = seconds
      end

      return unless Yamatanooroti.win?

      o.on_tail("windows specific yamatanooroti options")

      o.on_tail("--[no-]show-console",
                "Show test ongoing console.") do |show|
        if show == false and @terminal
          puts "Windows Terminal is always visible. --no-show-console is ignored."
        else
          @show_console = show
        end
      end

      o.on_tail("--[no-]close-console[=COND]", CLOSE_WHEN,
                "Close test target console when COND met",
                "(#{autorunner.keyword_display(CLOSE_WHEN)})") do |cond|
        @close_console = (cond.nil? ? :always : cond) || :never
      end
    end

    def self.apply_windows_terminal(type)
      @conhost = false
      @terminal = true
      @windows = type
      if @show_console == false
        puts "Windows Terminal is always visible. --no-show-console is ignored."
      end
      @show_console = true
    end

    def self.resolve_default!
      return unless Yamatanooroti.win?
      unless @wt || @terminal || @conhost
        @conhost = true
        @windows = :conhost
      end
    end

    def self.parse_require
      ::Test::Unit::AutoRunner.setup_option do |autorunner, o|
        parse_common(autorunner, o)
        next unless Yamatanooroti.win?

        o.on_tail("--windows=TYPE", CONHOST_TYPES + WT_TYPE,
                  "Specify console type",
                  "(#{autorunner.keyword_display(CONHOST_TYPES + WT_TYPE)})") do |type|
          if CONHOST_TYPES.include?(type)
            raise "Specify either --wt or --windows=conhost, not both." if @wt
            @conhost = true
            @terminal = false
            @windows = type
          else
            apply_windows_terminal(type)
          end
        end

        o.on_tail("--wt=PATH", String,
                  "Specify Windows Terminal executable path.",
                  "wt.exe on PATH is used if not specified.") do |path|
          raise "Specify either --wt or --windows=conhost, not both." if @conhost
          @wt = path
        end
      end
    end

    def self.parse_cli
      ::Test::Unit::AutoRunner.setup_option do |autorunner, o|
        parse_common(autorunner, o)
        next unless Yamatanooroti.win?

        o.on_tail("--windows=TYPE", CONHOST_TYPES + WT_TYPE + TERMINAL_TYPES,
                  "Specify console type",
                  "(#{autorunner.keyword_display(CONHOST_TYPES + WT_TYPE + TERMINAL_TYPES)})",
                  "(version prefix e.g. 1.22 resolves the latest matching release)") do |type|
          if CONHOST_TYPES.include?(type)
            @conhost = true
            @terminal = false
            @windows = type
          elsif WT_TYPE.include?(type)
            apply_windows_terminal(type)
          elsif TERMINAL_TYPES.include?(type) || type.to_s =~ TERMINAL_VERSION_RE
            apply_windows_terminal(WindowsTerminal.interpret(type))
          else
            raise "unknown --windows type: #{type}"
          end
        end

        o.on_tail("--wt-dir=DIR", String,
                  "Specify Windows Terminal working dir.",
                  "Automatically determined if not specified and treated temporary.",
                  "DIR is treated permanent if specified and download files are remains.") do |dir|
          @terminal_workdir = dir
        end

        o.on_tail("--refresh-wt-cache",
                  "Force re-fetch Windows Terminal releases refreshing the cache.") do
          @wt_refresh_cache = true
        end

        o.on_tail("--list-wt-releases[=all]", [:all],
                  "List downloadable Windows Terminal versions.",
                  "Without =all, show the latest preview and the latest stable,",
                  "plus the latest release per major.minor version.",
                  "With =all, show all releases (version and type, no URL).",
                  "Releases JSON is cached under --wt-dir.",
                  "When specified, the test run is skipped and the list is printed.") do |mode|
          @list_wt_releases = mode || :summary
        end
      end
    end

  end

  def self.options
    Options
  end
end
