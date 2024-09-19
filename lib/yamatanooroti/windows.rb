require 'test/unit'
require 'stringio'
require 'fiddle/import'
require 'fiddle/types'

module Yamatanooroti::WindowsDefinition
  extend Fiddle::Importer
  dlload 'kernel32.dll', 'user32.dll'
  include Fiddle::Win32Types

  FREE = Fiddle::Function.new(Fiddle::RUBY_FREE, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)

  typealias 'SHORT', 'short'
  typealias 'HWND', 'HANDLE'
  typealias 'LPVOID', 'void*'
  typealias 'LPWSTR', 'void*'
  typealias 'LPBYTE', 'void*'
  typealias 'LPCWSTR', 'void*'
  typealias 'LPCVOID', 'void*'
  typealias 'LPDWORD', 'void*'
  typealias 'WCHAR', 'unsigned short'
  typealias 'LPCWCH', 'void*'
  typealias 'LPSTR', 'void*'
  typealias 'LPCCH', 'void*'
  typealias 'LPBOOL', 'void*'
  typealias 'LPWORD', 'void*'
  typealias 'ULONG_PTR', 'ULONG*'
  typealias 'LONG', 'int'
  typealias 'HLOCAL', 'HANDLE'

  Fiddle::SIZEOF_DWORD = Fiddle::SIZEOF_LONG
  Fiddle::SIZEOF_WORD = Fiddle::SIZEOF_SHORT

  typealias 'COORD', 'DWORD32'
  SMALL_RECT = struct [
    'SHORT Left',
    'SHORT Top',
    'SHORT Right',
    'SHORT Bottom'
  ]
  typealias 'PSMALL_RECT', 'SMALL_RECT*'

  CONSOLE_SCREEN_BUFFER_INFO = struct [
    'SHORT dwSize_X', 'SHORT dwSize_Y', # 'COORD dwSize',
    'SHORT dwCursorPosition_X', 'SHORT dwCursorPosition_Y', #'COORD dwCursorPosition',
    'WORD wAttributes',
    'SHORT Left', 'SHORT Top', 'SHORT Right', 'SHORT Bottom', # 'SMALL_RECT srWindow',
    'SHORT MaxWidth', 'SHORT MaxHeight' # 'COORD dwMaximumWindowSize'
  ]
  typealias 'PCONSOLE_SCREEN_BUFFER_INFO', 'CONSOLE_SCREEN_BUFFER_INFO*'

  typealias 'COLORREF', 'DWORD'
  CONSOLE_SCREEN_BUFFER_INFOEX = struct [
    'ULONG cbSize',
    'SHORT dwSize_X', 'SHORT dwSize_Y', # 'COORD dwSize',
    'SHORT dwCursorPosition_X', 'SHORT dwCursorPosition_Y', #'COORD dwCursorPosition',
    'WORD wAttributes',
    'SHORT Left', 'SHORT Top', 'SHORT Right', 'SHORT Bottom', # 'SMALL_RECT srWindow',
    'SHORT MaxWidth', 'SHORT MaxHeight', # 'COORD dwMaximumWindowSize',
    'BOOL bFullScreenSupported',
    'COLORREF ColorTable[16]'
  ]
  typealias 'PCONSOLE_SCREEN_BUFFER_INFOEX', 'CONSOLE_SCREEN_BUFFER_INFOEX*'

  SECURITY_ATTRIBUTES = struct [
    'DWORD nLength',
    'LPVOID lpSecurityDescriptor',
    'BOOL bInheritHandle'
  ]
  typealias 'LPSECURITY_ATTRIBUTES', 'SECURITY_ATTRIBUTES*'

  STARTUPINFOW = struct [
    'DWORD cb',
    'LPWSTR lpReserved',
    'LPWSTR lpDesktop',
    'LPWSTR lpTitle',
    'DWORD dwX',
    'DWORD dwY',
    'DWORD dwXSize',
    'DWORD dwYSize',
    'DWORD dwXCountChars',
    'DWORD dwYCountChars',
    'DWORD dwFillAttribute',
    'DWORD dwFlags',
    'WORD wShowWindow',
    'WORD cbReserved2',
    'LPBYTE lpReserved2',
    'HANDLE hStdInput',
    'HANDLE hStdOutput',
    'HANDLE hStdError'
  ]
  typealias 'LPSTARTUPINFOW', 'STARTUPINFOW*'

  PROCESS_INFORMATION = struct [
    'HANDLE hProcess',
    'HANDLE hThread',
    'DWORD  dwProcessId',
    'DWORD  dwThreadId'
  ]
  typealias 'LPPROCESS_INFORMATION', 'PROCESS_INFORMATION*'

  INPUT_RECORD_WITH_KEY_EVENT = struct [
    'WORD EventType',
    'BOOL bKeyDown',
    'WORD wRepeatCount',
    'WORD wVirtualKeyCode',
    'WORD wVirtualScanCode',
    'WCHAR UnicodeChar',
    ## union 'CHAR  AsciiChar',
    'DWORD dwControlKeyState'
  ]

  STARTF_USESHOWWINDOW = 1
  CREATE_NEW_CONSOLE = 0x10
  CREATE_NEW_PROCESS_GROUP = 0x200
  CREATE_UNICODE_ENVIRONMENT = 0x400
  CREATE_NO_WINDOW = 0x08000000
  ATTACH_PARENT_PROCESS = -1
  KEY_EVENT = 0x0001
  SW_HIDE = 0
  SW_SHOWNOACTIVE = 4
  LEFT_ALT_PRESSED = 0x0002

  # BOOL CloseHandle(HANDLE hObject);
  extern 'BOOL CloseHandle(HANDLE);', :stdcall

  # BOOL FreeConsole(void);
  extern 'BOOL FreeConsole(void);', :stdcall
  # BOOL AttachConsole(DWORD dwProcessId);
  extern 'BOOL AttachConsole(DWORD);', :stdcall
  # HWND WINAPI GetConsoleWindow(void);
  extern 'HWND GetConsoleWindow(void);', :stdcall
  # BOOL WINAPI SetConsoleWindowInfo(HANDLE hConsoleOutput, BOOL bAbsolute, const SMALL_RECT *lpConsoleWindow);
  extern 'BOOL SetConsoleWindowInfo(HANDLE, BOOL, PSMALL_RECT);', :stdcall
  # BOOL WriteConsoleInputW(HANDLE hConsoleInput, const INPUT_RECORD *lpBuffer, DWORD nLength, LPDWORD lpNumberOfEventsWritten);
  extern 'BOOL WriteConsoleInputW(HANDLE, const INPUT_RECORD*, DWORD, LPDWORD);', :stdcall
  # SHORT VkKeyScanW(WCHAR ch);
  extern 'SHORT VkKeyScanW(WCHAR);', :stdcall
  # UINT MapVirtualKeyW(UINT uCode, UINT uMapType);
  extern 'UINT MapVirtualKeyW(UINT, UINT);', :stdcall
  # BOOL GetNumberOfConsoleInputEvents(HANDLE  hConsoleInput, LPDWORD lpcNumberOfEvents);
  extern 'BOOL GetNumberOfConsoleInputEvents(HANDLE  hConsoleInput, LPDWORD lpcNumberOfEvents);', :stdcall
  # BOOL WINAPI ReadConsoleOutputCharacterW(HANDLE hConsoleOutput, LPWSTR lpCharacter, DWORD nLength, COORD dwReadCoord, LPDWORD lpNumberOfCharsRead);
  extern 'BOOL ReadConsoleOutputCharacterW(HANDLE, LPWSTR, DWORD, COORD, LPDWORD);', :stdcall
  # BOOL WINAPI GetConsoleScreenBufferInfo(HANDLE hConsoleOutput, PCONSOLE_SCREEN_BUFFER_INFO lpConsoleScreenBufferInfo);
  extern 'BOOL GetConsoleScreenBufferInfo(HANDLE, PCONSOLE_SCREEN_BUFFER_INFO);', :stdcall
  # BOOL WINAPI GetConsoleScreenBufferInfoEx(HANDLE hConsoleOutput, PCONSOLE_SCREEN_BUFFER_INFOEX lpConsoleScreenBufferInfoEx);
  extern 'BOOL GetConsoleScreenBufferInfoEx(HANDLE, PCONSOLE_SCREEN_BUFFER_INFOEX);', :stdcall
  # BOOL WINAPI SetConsoleScreenBufferInfoEx(HANDLE hConsoleOutput, PCONSOLE_SCREEN_BUFFER_INFOEX lpConsoleScreenBufferInfoEx);
  extern 'BOOL SetConsoleScreenBufferInfoEx(HANDLE, PCONSOLE_SCREEN_BUFFER_INFOEX);', :stdcall

  # BOOL CreateProcessW(LPCWSTR lpApplicationName, LPWSTR lpCommandLine, LPSECURITY_ATTRIBUTES lpProcessAttributes, LPSECURITY_ATTRIBUTES lpThreadAttributes, BOOL bInheritHandles, DWORD dwCreationFlags, LPVOID lpEnvironment, LPCWSTR lpCurrentDirectory, LPSTARTUPINFOW lpStartupInfo, LPPROCESS_INFORMATION lpProcessInformation);
  extern 'BOOL CreateProcessW(LPCWSTR lpApplicationName, LPWSTR lpCommandLine, LPSECURITY_ATTRIBUTES lpProcessAttributes, LPSECURITY_ATTRIBUTES lpThreadAttributes, BOOL bInheritHandles, DWORD dwCreationFlags, LPVOID lpEnvironment, LPCWSTR lpCurrentDirectory, LPSTARTUPINFOW lpStartupInfo, LPPROCESS_INFORMATION lpProcessInformation);', :stdcall

  # int MultiByteToWideChar(UINT CodePage, DWORD dwFlags, LPCSTR lpMultiByteStr, int cbMultiByte, LPWSTR lpWideCharStr, int cchWideChar);
  extern 'int MultiByteToWideChar(UINT, DWORD, LPCSTR, int, LPWSTR, int);', :stdcall
  # int WideCharToMultiByte(UINT CodePage, DWORD dwFlags, _In_NLS_string_(cchWideChar)LPCWCH lpWideCharStr, int cchWideChar, LPSTR lpMultiByteStr, int cbMultiByte, LPCCH lpDefaultChar, LPBOOL lpUsedDefaultChar);
  extern 'int WideCharToMultiByte(UINT, DWORD, LPCWCH, int, LPSTR, int, LPCCH, LPBOOL);', :stdcall

  # HANDLE CreateFileA(LPCSTR lpFileName, DWORD dwDesiredAccess, DWORD dwShareMode, LPSECURITY_ATTRIBUTES lpSecurityAttributes, DWORD dwCreationDisposition, DWORD dwFlagsAndAttributes, HANDLE hTemplateFile);
  extern 'HANDLE CreateFileA(LPCSTR, DWORD, DWORD, LPSECURITY_ATTRIBUTES, DWORD, DWORD, HANDLE);', :stdcall
  GENERIC_READ = 0x80000000
  GENERIC_WRITE = 0x40000000
  FILE_SHARE_READ = 0x00000001
  FILE_SHARE_WRITE = 0x00000002
  OPEN_EXISTING = 3
  INVALID_HANDLE_VALUE = 0xffffffff

  extern 'DWORD FormatMessageW(DWORD dwFlags, LPCVOID lpSource, DWORD dwMessageId, DWORD dwLanguageId, LPWSTR lpBuffer, DWORD nSize, va_list *Arguments);', :stdcall
  extern 'HLOCAL LocalFree(HLOCAL hMem);', :stdcall
  FORMAT_MESSAGE_ALLOCATE_BUFFER = 0x00000100
  FORMAT_MESSAGE_FROM_SYSTEM = 0x00001000

  private def error_message(r, method_name)
    return if not r.zero?
    err = Fiddle.win32_last_error
    string = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
    n = FormatMessageW(
      FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
      Fiddle::NULL,
      err,
      0x0,
      string,
      0,
      Fiddle::NULL
    )
    if n > 0
      str = wc2mb(string.ptr[0, n * 2])
      LocalFree(string)
      $stderr.puts "ERROR(#{method_name}): #{err.to_s}: #{str}"
    end
  end

  def get_console_screen_buffer_info(handle)
    csbi = CONSOLE_SCREEN_BUFFER_INFO.malloc
    r = GetConsoleScreenBufferInfo(handle, csbi)
    error_message(r, 'GetConsoleScreenBufferInfo')
    r == 0 ? nil : csbi
  end

  def set_console_screen_buffer_info_ex(handle, h, w, buffer_height)
    csbi = CONSOLE_SCREEN_BUFFER_INFOEX.malloc
    csbi.cbSize = CONSOLE_SCREEN_BUFFER_INFOEX.size
    r = GetConsoleScreenBufferInfoEx(handle, csbi)
    error_message(r, 'GetConsoleScreenBufferSize')
    csbi.dwSize_X = w
    csbi.dwSize_Y = buffer_height
    csbi.Left = 0
    csbi.Right = w - 1
    csbi.Top = [csbi.Top, buffer_height - h].min
    csbi.Bottom = csbi.Top + h - 1
    r = SetConsoleScreenBufferInfoEx(handle, csbi)
    error_message(r, 'SetConsoleScreenBufferInfoEx')
    return r != 0
  end

  def set_console_window_info(handle, h, w)
    rect = SMALL_RECT.malloc
    rect.Left = 0
    rect.Top = 0
    rect.Right = w - 1
    rect.Bottom = h - 1
    r = SetConsoleWindowInfo(handle, 1, rect)
    error_message(r, 'SetConsoleWindowInfo')
    return r != 0
  end

  def set_console_window_size(handle, h, w)
    # expand buffer size to keep scrolled away lines
    buffer_h = h + 100

    r = set_console_screen_buffer_info_ex(handle, h, w, buffer_h)
    return false unless r

    r = set_console_window_info(handle, h, w)
    return false unless r

    return true
  end

  def create_console_file_handle(name)
    fh = CreateFileA(
      name,
      GENERIC_READ | GENERIC_WRITE,
      FILE_SHARE_READ | FILE_SHARE_WRITE,
      nil,
      OPEN_EXISTING,
      0,
      0
    )
    fh = [fh].pack("J").unpack1("J")
    error_message(0, name) if fh == INVALID_HANDLE_VALUE
    fh
  end

  def close_handle(handle)
    r = CloseHandle(handle)
    error_message(r, "CloseHandle")
    return r != 0
  end

  def free_console
    r = FreeConsole()
    error_message(r, "FreeConsole")
    return r != 0
  end

  def attach_console(pid = ATTACH_PARENT_PROCESS, maybe_fail: false)
    r = AttachConsole(pid)
    error_message(r, 'AttachConsole') unless maybe_fail
    return r != 0
  end

  def create_console(command)
    converted_command = mb2wc("#{command}\x00")
    console_process_info = PROCESS_INFORMATION.malloc
    console_process_info.to_ptr[0, PROCESS_INFORMATION.size] = "\x00".b * PROCESS_INFORMATION.size
    startup_info = STARTUPINFOW.malloc
    startup_info.to_ptr[0, STARTUPINFOW.size] = "\x00".b * STARTUPINFOW.size
    startup_info.cb = STARTUPINFOW.size
    if ENV['YAMATANOOROTI_SHOW_WINDOW']
      startup_info.dwFlags = STARTF_USESHOWWINDOW
      startup_info.wShowWindow = SW_SHOWNOACTIVE
    else
      startup_info.dwFlags = STARTF_USESHOWWINDOW
      startup_info.wShowWindow = SW_HIDE
    end

    r = CreateProcessW(
      Fiddle::NULL, converted_command,
      Fiddle::NULL, Fiddle::NULL,
      0,
      CREATE_NEW_CONSOLE | CREATE_UNICODE_ENVIRONMENT,
      Fiddle::NULL, Fiddle::NULL,
      startup_info, console_process_info
    )
    error_message(r, 'CreateProcessW')
    return nil if r == 0
    console_process_info
  end

  def mb2wc(str)
    size = MultiByteToWideChar(65001, 0, str, str.bytesize, '', 0)
    converted_str = "\x00".b * (size * 2)
    MultiByteToWideChar(65001, 0, str, str.bytesize, converted_str, size)
    converted_str
  end

  def wc2mb(str)
    size = WideCharToMultiByte(65001, 0, str, str.bytesize / 2, '', 0, 0, 0)
    converted_str = "\x00".b * size
    WideCharToMultiByte(65001, 0, str, str.bytesize / 2, converted_str, converted_str.bytesize, 0, 0)
    converted_str.force_encoding("UTF-8")
  end

  def read_console_output(handle, row, width)
    buffer_chars = width * 8
    buffer = "\0".b * Fiddle::SIZEOF_SHORT * buffer_chars
    n = "\0".b * Fiddle::SIZEOF_DWORD
    r = ReadConsoleOutputCharacterW(handle, buffer, width, row << 16, n)
    error_message(r, "ReadConsoleOutputCharacterW")
    return r == 0 ? nil : wc2mb(buffer[0, n.unpack1("L") * 2]).gsub(/ *$/, "")
  end

  def set_input_record(r, code)
    r.EventType = KEY_EVENT
    # r.bKeyDown = 1
    r.wRepeatCount = 1
    r.dwControlKeyState = code < 0 ? LEFT_ALT_PRESSED : 0
    code = code.abs
    r.wVirtualKeyCode = VkKeyScanW(code)
    r.wVirtualScanCode = MapVirtualKeyW(code, 0)
    r.UnicodeChar = code
  end

  def write_console_input(handle, records, n)
    written = "\0".b * Fiddle::SIZEOF_DWORD
    r = WriteConsoleInputW(handle, records, n, written)
    error_message(r, 'WriteConsoleInput')
    return r == 0 ? nil : written.unpack1('L')
  end

  def get_number_of_console_input_events(handle)
    n = "\0".b * Fiddle::SIZEOF_DWORD
    r = GetNumberOfConsoleInputEvents(handle, n)
    error_message(r, 'GetNumberOfConsoleInputEvents')
    return r == 0 ? nil : n.unpack1('L')
  end

  extend self
end

module Yamatanooroti::WindowsTestCaseModule
  DL = Yamatanooroti::WindowsDefinition

  class TargetConhostManager
    def self.setup_console(height, width)
      begin
        instance = self.new(height, width)
      rescue
        nil
      end
      instance
    end

    def initialize(height, width)
      command = %q[ruby.exe --disable=gems -e sleep"] # console keeping process
      @console_process_info = DL.create_console(command)
      raise if @console_process_info == nil
      @console_process_id = @console_process_info.dwProcessId

      # wait for console startup complete
      8.times do |n|
        break if attach { true }
        sleep 0.02 * 2**n
      end

      attach do |conin, conout|
        DL.set_console_window_size(conout, height, width)
      end
    end

    def attach(open = true)
      stderr = $stderr
      $stderr = StringIO.new
      conin = conout = nil

      DL.free_console
      # this can be fail while new process is starting
      r = DL.attach_console(@console_process_id, maybe_fail: true)
      return nil unless r

      if open
        conin = DL.create_console_file_handle("conin$")
        return nil if conin == DL::INVALID_HANDLE_VALUE

        conout = DL.create_console_file_handle("conout$")
        return nil if conout == DL::INVALID_HANDLE_VALUE
      end

      yield(conin, conout)
    rescue => evar
    ensure
      DL.close_handle(conin) if conin && conin != DL::INVALID_HANDLE_VALUE
      DL.close_handle(conout) if conout && conout != DL::INVALID_HANDLE_VALUE
      DL.free_console
      DL.attach_console
      $stderr.rewind
      stderr.write $stderr.read
      $stderr = stderr
      raise evar if evar
    end

    def close
      system("taskkill.exe", "/PID", "#{@console_process_info.dwProcessId}", {[:out, :err] => "NUL"}) unless ENV['YAMATANOOROTI_NO_CLOSE']
      DL.close_handle(@console_process_info.hProcess)
      DL.close_handle(@console_process_info.hThread)
    end

    def setup_cp(cp)
      if cp
        attach { system("chcp #{Integer(cp)} > NUL") }
      end
    end

    def launch(command)
      @target = attach(false) do
        TargetProcessManager.new(command)
      end
      @target
    end

    def retrieve_screen(top_of_buffer: false)
      top, bottom, left, right = attach do |conin, conout|
        csbi = DL.get_console_screen_buffer_info(conout)
        if top_of_buffer
          [0, csbi.Bottom, csbi.Left, csbi.Right]
        else
          [csbi.Top, csbi.Bottom, csbi.Left, csbi.Right]
        end
      end

      width = right - left + 1
      buffer_chars = width * 8
      buffer = Fiddle::Pointer.malloc(Fiddle::SIZEOF_SHORT * buffer_chars, DL::FREE)
      lines = attach do |conin, conout|
        (top..bottom).map do |y|
          DL.read_console_output(conout, y, width) || ""
        end
      end
      lines
    end

    def write(str)
      codes = str.chars.map do |c|
        c = "\r" if c == "\n"
        byte = c.getbyte(0)
        if c.bytesize == 1 and byte.allbits?(0x80) # with Meta key
          [-(byte ^ 0x80)]
        else
          DL.mb2wc(c).unpack("S*")
        end
      end.flatten
      record = DL::INPUT_RECORD_WITH_KEY_EVENT.malloc
      records = codes.reduce("".b) do |records, code|
        DL.set_input_record(record, code)
        record.bKeyDown = 1
        records << record.to_ptr.to_str
        record.bKeyDown = 0
        records << record.to_ptr.to_str
      end
      attach do |conin, conout|
        DL.write_console_input(conin, records, codes.size * 2)
        loop do
          sleep 0.02
          n = DL.get_number_of_console_input_events(conin)
          break if n == 0
          break if n.nil?
          @target.sync
          break if @target.closed?
        end
      end
    end
  end

  private def quote_command_arg(arg)
    if not arg.match?(/[ \t"]/)
      # No quotation needed.
      return arg
    end

    if not arg.match?(/["\\]/)
      # No embedded double quotes or backlashes, so I can just wrap quote
      # marks around the whole thing.
      return %{"#{arg}"}
    end

    quote_hit = true
    result = +'"'
    arg.chars.reverse.each do |c|
      result << c
      if quote_hit and c == '\\'
        result << '\\'
      elsif c == '"'
        quote_hit = true
        result << '\\'
      else
        quote_hit = false
      end
    end
    result << '"'
    result.reverse
  end

####################
  class TargetWindowsTerminalManager < TargetConhostManager

def do_tasklist(filter)
  list = loop do
    sleep 0.1
    tasklist_out = `tasklist /FI "#{filter}"`.lines
    break tasklist_out if tasklist_out.length == 4
    if tasklist_out.length > 4
      return 0
    end
  end
  pid_start = list[2].index(/ \K=/)
  list[3][pid_start..-1].to_i
end

def pid_from_imagename(name)
  do_tasklist("IMAGENAME eq #{name}")
end

def pid_from_windowtitle(name)
  do_tasklist("WINDOWTITLE eq #{name}")
end

def pid_from_pid(pid)
  do_tasklist("PID eq #{pid}")
end

    def new_id
      self.class.class_exec do
        @count ||= 0
        id = "yamaoro#{Process.pid}##{@count}"
        @count = @count + 1
        return id
      end
    end

    def close
      @process_list.each { |pid|
        system("taskkill.exe", "/F", "/PID", "#{pid}", {[:out, :err] => "NUL"}) unless ENV['YAMATANOOROTI_NO_CLOSE']
      }
      #DL.close_handle(@console_process_handle)
      Process.kill("KILL", @wt_pid)
    end

    def new_wt(rows, cols, split = false)
      while true
        wt_id = new_id
        marker_command = %w[findstr.exe yamatanooroti]
        keeper_command = %w[choice.exe /N]

        command = "cmd /s /c \"wt.exe -w #{wt_id} --size #{cols},#{rows} nt --title #{wt_id} #{marker_command.join(" ")}\""
        spawn(command)
        sleep 0.25
        wt_pid = pid_from_windowtitle(wt_id)
        marker_pid = pid_from_imagename(marker_command[0])

        if marker_pid == 0
          system("taskkill /PID #{wt_pid} /F /T")
          sleep 0.1 + rand
          redo
        end
        @console_process_id = marker_pid

        keeper_pid, keeper_writer = attach(marker_pid) do
          r, w = IO.pipe
          pid = spawn(keeper_command.join(" "), {in: r})
          r.close
          [pid, w]
        end
        pid_from_pid(keeper_pid)
        Process.kill("KILL", marker_pid)

        @wt_id = wt_id
        @wt_pid = wt_pid
        @console_process_id = keeper_pid
        @keeper_writer = keeper_writer
        return keeper_pid
      end
    end

    def get_size
      @size = attach(@console_process_id) do |conin, conout|
        csbi = DL.get_console_screen_buffer_info(conout)
        #$stderr.puts [csbi.Bottom + 1, csbi.Right + 1].inspect
        [csbi.Bottom + 1, csbi.Right + 1]
      end
    end

    def self.setup_console(height, width)
      if @minimum_width.nil? || @minimum_width <= width
        wt = self.new(height, width)
        return nil unless wt
      end
      if wt
        size = wt.get_size
        if size == [height, width]
          return wt 
        else
          @minimum_width = size[1]
          @div_to_width ||= {}
          @width_to_div ||= {}
          wt.close
        end
      end
      expanded_size = @minimum_width + 30
      wt = self.new(height, expanded_size)
      div = @width_to_div[width]
      div ||= (width * 98 + (@minimum_width - width) * 9) / (expanded_size - 5)
      loop do
        w = dw = @div_to_width[div]
        unless w
          wt.split(div/100.0)
          size = wt.get_size
          @div_to_width[div] = w = size[1]
        end
        if w == width
          wt.split(div/100.0) if dw
          @width_to_div[width] = div
          return wt
        else
          unless dw
            wt.close_pane
            sleep 0.25
          end
          if w > width
            div -= 1
            if div <= 0
              return nil
            end
          else
            div += 1
            if div >= 100
              return nil
            end
          end
        end
      end
    end

    def initialize(height, width, split = false)
      @process_list = [new_wt(height, width, split)]
    end

    def split(div = 0.5)
      marker_command = %w[findstr.exe yamatanooroti]
      keeper_command = %w[choice.exe /N]
      command = "cmd /s /c \"wt.exe -w #{@wt_id} sp -V --title #{@wt_id} -s #{div} #{marker_command.join(" ")}\""
      spawn(command)
      sleep 0.25
      marker_pid = pid_from_imagename(marker_command[0])

      if marker_pid == 0
        return nil
      end
      @console_process_id = marker_pid

      keeper_pid, keeper_writer = attach(marker_pid) do
        r, w = IO.pipe
        pid = spawn(keeper_command.join(" "), {in: r})
        r.close
        [pid, w]
      end
      pid_from_pid(keeper_pid)
      Process.kill("KILL", marker_pid)
      @console_process_id = keeper_pid
      @process_list << keeper_pid
    end

    def close_pane
      system("taskkill.exe", "/F", "/PID", "#{@process_list.pop}", {[:out, :err] => "NUL"})
      @console_process_id = @process_list[-1]
    end

  #  private :new
  end
####################

  class TargetProcessManager
    def initialize(command)
      @errin, err = IO.pipe
      @pid = spawn(command, {in: ["conin$", File::RDWR | File::BINARY], out: ["conout$", File::RDWR | File::BINARY], err: err})
      err.close
      @closed = false
      @status = nil
      @q = Thread::Queue.new
      @t = Thread.new do
        begin
          err = @errin.gets
          @q << err if err
        rescue IOError
          # target process already terminated
          next
        end
      end
    end

    def terminate
      system("taskkill.exe", "/PID", "#{@pid}", {[:out, :err] => "NUL"})
    end

    def closed?
      @closed ||= !(@status = Process.wait2(@pid, Process::WNOHANG)).nil?
    end

    private def consume(buffer)
      while !@q.empty?
        buffer << @q.shift
      end
    end

    def ensure_close
      @errin.close if !@errin.closed?
    end

    def sync
      buffer = ""
      if closed?
        @t.kill
        @t.join
        consume(buffer)
        rest = "".b
        while ((str = @errin.read_nonblock(1024, exception: false)).is_a?(String)) do
          rest << str
        end
        buffer << rest.force_encoding(Encoding.default_external) << "\n" if rest != ""
      else
        consume(buffer)
      end
      $stderr.write buffer if buffer != ""
    end
  end

  def write(str)
    @console.write(str)
  end

  def close
    @target.sync
    sleep @wait if !@target.closed?
    # read first before kill the console process including output
    @result = @console.retrieve_screen

    @target.terminate
    @console.close
    @target.sync
    @target.ensure_close
  end

  def result
    @result
  end

  def assert_screen(expected_lines, message = nil)
    case expected_lines
    when Array
      assert_equal(expected_lines, @result, message)
    when String
      assert_equal(expected_lines, @result.join("\n").sub(/\n*\z/, "\n"), message)
    end
  end

  def codepage_success?
    @codepage_success_p
  end

  def start_terminal(height, width, command, wait: 1, startup_message: nil)
    start_terminal_with_cp(height, width, command, wait: wait, startup_message: startup_message)
  end

  def start_terminal_with_cp(height, width, command, wait: 1, startup_message: nil, codepage: nil)
    @wait = wait * (ENV['YAMATANOOROTI_WAIT_RATIO']&.to_f || 1.0)
    @result = nil
    @console = TargetWindowsTerminalManager.setup_console(height, width)
    @codepage_success_p = @console.setup_cp(codepage)
    @target = @console.launch(command.map{ |c| quote_command_arg(c) }.join(' '))
    sleep @wait
    case startup_message
    when String
      check_startup_message = ->(message) {
        message.start_with?(
          startup_message.each_char.each_slice(width).map(&:join).join("\n").gsub(/ +\n/, "\n")
        )
      }
    when Regexp
      check_startup_message = ->(message) { startup_message.match?(message) }
    end
    if check_startup_message
      loop do
        screen = @console.retrieve_screen(top_of_buffer: true).join("\n").sub(/\n*\z/, "\n")
        break if check_startup_message.(screen)
        @target.sync
        break if @target.closed?
        sleep 0.1
      end
    end
  end
end

class Yamatanooroti::WindowsTestCase < Test::Unit::TestCase
  include Yamatanooroti::WindowsTestCaseModule
end
