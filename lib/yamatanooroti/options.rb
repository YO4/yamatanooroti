class Yamatanooroti
  module Options
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

      # fetch the releases JSON. overridable for testing.
      def self.fetch_releases
        require 'open3'
        out, status = Open3.capture2("curl", "-sS", "-L", RELEASES_API)
        raise "failed to fetch windows terminal releases: #{RELEASES_API}" unless status.success?
        require 'json'
        JSON.parse(out)
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

      # resolve a release by version prefix (e.g. "1.22") taking the latest.
      # spec: returns { version:, url:, sha256: } or nil when no match.
      def self.resolve_by_prefix(prefix)
        releases = fetch_releases
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
        releases = fetch_releases
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
      @default_wait = 0.01
      @default_timeout = 2.0
      @windows = Yamatanooroti.win? ? :conhost : nil
      @conhost = false
      @terminal = false
      @terminal_workdir = nil
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
      end
    end

  end

  def self.options
    Options
  end
end
