class Yamatanooroti::ConhostTerm
  include Yamatanooroti::WindowsTermMixin

  def self.setup_console(height, width, wait, timeout, name)
    new(height, width, wait, timeout, name)
  end

  attr_reader :console_process_id

  def initialize(height, width, wait, timeout, name)
    check_interrupt
    @wait = wait
    @timeout = timeout
    @name = name
    @result = nil
    @codepage_success_p = nil
    @wrote_and_not_yet_waited = false

    countup_testcase_title(name)
    pipename = get_pipename(name)
    @pipe_handle = DL.create_named_pipe(pipename)
    DL.create_console(keeper_commandline(pipename), show_console_param())

    # wait for console startup complete
    with_timeout("Console process startup timed out.") do
      @console_process_id = DL.get_named_pipe_client_processid(@pipe_handle, maybe_fail: true)
    end

    attach_terminal do |conin, conout|
      DL.set_console_window_size(conout, height, width)
    end
  end

  def close_console(need_to_close = true)
    if @console_process_id
      if (need_to_close)
        if @target && !@target.closed?
          @target.close
        end
        DL.close_handle(@pipe_handle)
      else
        castling(@pipe_handle)
      end
      @console_process_id = @pipe_handle = nil
    end
  end

  def close!
    close_console(!Yamatanooroti.options.show_console)
  end
end
