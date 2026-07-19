class Yamatanooroti
  module Options
    @list_wt_releases = nil
    class << self
      attr_accessor :list_wt_releases
    end

    # Windows only: if --list-wt-releases was requested, print the list and exit.
    # deferred until after all options (including --wt-dir) are parsed so the
    # cache directory is known.
    def self.run_list_if_requested
      return unless @list_wt_releases
      Yamatanooroti::WindowsConsoleSetup::WindowsTerminal.list_releases(detail: @list_wt_releases == :all,
                                                                        force: Yamatanooroti.options.wt_refresh_cache)
      exit
    end

    # Windows only: register the deferred list action once test/unit is available.
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

      install_list_hook

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
            apply_windows_terminal(Yamatanooroti::WindowsConsoleSetup::WindowsTerminal.interpret(type))
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
