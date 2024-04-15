require 'test/unit'
require 'stringio'
require 'fiddle/import'
require 'fiddle/types'

module Yamatanooroti::WindowsDefinition
  extend Fiddle::Importer
  dlload 'kernel32.dll', 'psapi.dll', 'user32.dll'
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
  typealias 'LPTSTR', 'void*'
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

  PROCESSENTRY32W = struct [
    'DWORD dwSize',
    'DWORD cntUsage',
    'DWORD th32ProcessID',
    'ULONG_PTR th32DefaultHeapID',
    'DWORD th32ModuleID',
    'DWORD cntThreads',
    'DWORD th32ParentProcessID',
    'LONG pcPriClassBase',
    'DWORD dwFlags',
    'WCHAR szExeFile[260]'
  ]
  typealias 'LPPROCESSENTRY32W', 'PROCESSENTRY32W*'

  STARTF_USESHOWWINDOW = 1
  CREATE_NEW_CONSOLE = 0x10
  CREATE_NEW_PROCESS_GROUP = 0x200
  CREATE_UNICODE_ENVIRONMENT = 0x400
  CREATE_NO_WINDOW = 0x08000000
  ATTACH_PARENT_PROCESS = -1
  KEY_EVENT = 0x0001
  TH32CS_SNAPPROCESS = 0x00000002
  PROCESS_ALL_ACCESS = 0x001FFFFF
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
  # BOOL WINAPI ReadConsoleOutputCharacterW(HANDLE hConsoleOutput, LPTSTR lpCharacter, DWORD nLength, COORD dwReadCoord, LPDWORD lpNumberOfCharsRead);
  extern 'BOOL ReadConsoleOutputCharacterW(HANDLE, LPTSTR, DWORD, COORD, LPDWORD);', :stdcall
  # BOOL WINAPI GetConsoleScreenBufferInfo(HANDLE hConsoleOutput, PCONSOLE_SCREEN_BUFFER_INFO lpConsoleScreenBufferInfo);
  extern 'BOOL GetConsoleScreenBufferInfo(HANDLE, PCONSOLE_SCREEN_BUFFER_INFO);', :stdcall
  # BOOL WINAPI GetConsoleScreenBufferInfoEx(HANDLE hConsoleOutput, PCONSOLE_SCREEN_BUFFER_INFOEX lpConsoleScreenBufferInfoEx);
  extern 'BOOL GetConsoleScreenBufferInfoEx(HANDLE, PCONSOLE_SCREEN_BUFFER_INFOEX);', :stdcall
  # BOOL WINAPI SetConsoleScreenBufferInfoEx(HANDLE hConsoleOutput, PCONSOLE_SCREEN_BUFFER_INFOEX lpConsoleScreenBufferInfoEx);
  extern 'BOOL SetConsoleScreenBufferInfoEx(HANDLE, PCONSOLE_SCREEN_BUFFER_INFOEX);', :stdcall

  # BOOL CreateProcessW(LPCWSTR lpApplicationName, LPWSTR lpCommandLine, LPSECURITY_ATTRIBUTES lpProcessAttributes, LPSECURITY_ATTRIBUTES lpThreadAttributes, BOOL bInheritHandles, DWORD dwCreationFlags, LPVOID lpEnvironment, LPCWSTR lpCurrentDirectory, LPSTARTUPINFOW lpStartupInfo, LPPROCESS_INFORMATION lpProcessInformation);
  extern 'BOOL CreateProcessW(LPCWSTR lpApplicationName, LPWSTR lpCommandLine, LPSECURITY_ATTRIBUTES lpProcessAttributes, LPSECURITY_ATTRIBUTES lpThreadAttributes, BOOL bInheritHandles, DWORD dwCreationFlags, LPVOID lpEnvironment, LPCWSTR lpCurrentDirectory, LPSTARTUPINFOW lpStartupInfo, LPPROCESS_INFORMATION lpProcessInformation);', :stdcall
  # HANDLE CreateToolhelp32Snapshot(DWORD dwFlags, DWORD th32ProcessID);
  extern 'HANDLE CreateToolhelp32Snapshot(DWORD, DWORD);', :stdcall
  # BOOL Process32First(HANDLE hSnapshot, LPPROCESSENTRY32W lppe);
  extern 'BOOL Process32FirstW(HANDLE, LPPROCESSENTRY32W);', :stdcall
  # BOOL Process32Next(HANDLE hSnapshot, LPPROCESSENTRY32 lppe);
  extern 'BOOL Process32NextW(HANDLE, LPPROCESSENTRY32W);', :stdcall
  # DWORD GetCurrentProcessId();
  extern 'DWORD GetCurrentProcessId();', :stdcall
  # HANDLE OpenProcess(DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwProcessId);
  extern 'HANDLE OpenProcess(DWORD, BOOL, DWORD);', :stdcall
  # BOOL TerminateProcess(HANDLE hProcess, UINT uExitCode);
  extern 'BOOL TerminateProcess(HANDLE, UINT);', :stdcall
  #BOOL TerminateThread(HANDLE hThread, DWORD dwExitCode);
  extern 'BOOL TerminateThread(HANDLE, DWORD);', :stdcall

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

  extern 'DWORD FormatMessage(DWORD dwFlags, LPCVOID lpSource, DWORD dwMessageId, DWORD dwLanguageId, LPTSTR lpBuffer, DWORD nSize, va_list *Arguments);', :stdcall
  extern 'HLOCAL LocalFree(HLOCAL hMem);', :stdcall
  def self.GetLastError
    Fiddle.win32_last_error
  end
  FORMAT_MESSAGE_ALLOCATE_BUFFER = 0x00000100
  FORMAT_MESSAGE_FROM_SYSTEM = 0x00001000

  private def error_message(err, method_name)
    string = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
    FormatMessage(
      FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
      Fiddle::NULL,
      err,
      0x0,
      string,
      0,
      Fiddle::NULL
    )
    str = string.ptr.to_s
    LocalFree(string)
    str.force_encoding("Windows-31J")
    puts "ERROR(#{method_name}): #{err.to_s}: #{string.ptr.to_s.force_encoding("locale")}"
  end

  def get_console_screen_buffer_info(handle)
    csbi = CONSOLE_SCREEN_BUFFER_INFO.malloc
    r = GetConsoleScreenBufferInfo(handle, csbi)
    puts error_message(r, 'GetConsoleScreenBufferInfo') if r == 0
    r == 0 ? nil : csbi
  end

  def set_console_screen_buffer_info_ex(handle, h, w, buffer_height)
    csbi = CONSOLE_SCREEN_BUFFER_INFOEX.malloc
    csbi.cbSize = CONSOLE_SCREEN_BUFFER_INFOEX.size
    r = GetConsoleScreenBufferInfoEx(handle, csbi)
    error_message(r, 'GetConsoleScreenBufferSize') if r == 0
    csbi.dwSize_X = w
    csbi.dwSize_Y = buffer_height
    csbi.Left = 0
    csbi.Right = w - 1
    csbi.Top = [csbi.Top, buffer_height - h].min
    csbi.Bottom = csbi.Top + h - 1
    r = SetConsoleScreenBufferInfoEx(handle, csbi)
    puts error_message(r, 'SetConsoleScreenBufferInfoEx') if r == 0
    return r != 0
  end

  def set_console_window_info(handle, h, w)
    rect = SMALL_RECT.malloc
    rect.Left = 0
    rect.Top = 0
    rect.Right = w - 1
    rect.Bottom = h - 1
    r = SetConsoleWindowInfo(handle, 1, rect)
    puts error_message(r, 'SetConsoleWindowInfo') if r == 0
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

  extend self
end

module Yamatanooroti::WindowsTestCaseModule
  DL = Yamatanooroti::WindowsDefinition

  private def in_child
    stderr = $stderr
    $stderr = StringIO.new
    conin = conout = nil
    r = DL.FreeConsole()
    error_message(r, "FreeConsole")
    r = DL.AttachConsole(@console_process_info.dwProcessId)
    # this can be fail while new process is starting
    # error_message(r, 'AttachConsole')
    return nil if r.zero?
    conin = DL.CreateFileA(
      "conin$",
      DL::GENERIC_READ | DL::GENERIC_WRITE,
      DL::FILE_SHARE_READ | DL::FILE_SHARE_WRITE,
      nil,
      DL::OPEN_EXISTING,
      0,
      0
    )
    error_message(conin.to_i == DL::INVALID_HANDLE_VALUE ? 0 : 1, "conin$")
    return nil if conin.to_i == DL::INVALID_HANDLE_VALUE
    conout = DL.CreateFileA(
      "conout$",
      DL::GENERIC_READ | DL::GENERIC_WRITE,
      DL::FILE_SHARE_READ | DL::FILE_SHARE_WRITE,
      nil,
      DL::OPEN_EXISTING,
      0,
      0
    )
    error_message(conout.to_i == DL::INVALID_HANDLE_VALUE ? 0 : 1, "conout$")
    return nil if conout.to_i == DL::INVALID_HANDLE_VALUE
    yield(conin.to_i, conout.to_i)
  rescue => evar
  ensure
    if conin != nil && conin.to_i != DL::INVALID_HANDLE_VALUE
      r = DL.CloseHandle(conin)
      error_message(r, "CloseHandle")
    end
    if conout != nil && conout.to_i != DL::INVALID_HANDLE_VALUE
      r = DL.CloseHandle(conout)
      error_message(r, "CloseHandle")
    end
    r = DL.FreeConsole()
    error_message(r, "FreeConsole")
    r = DL.AttachConsole(DL::ATTACH_PARENT_PROCESS)
    error_message(r, 'AttachConsole')
    stderr.write $stderr.read
    $stderr = stderr
    raise evar if evar
  end

  private def setup_console(height, width)
    command = %q[ruby.exe --disable=gems -e sleep"] # 'DO NOTHING JUST STAY THERE' CONSOLE KEEPING PROCESS
    converted_command = mb2wc("#{command}\x00")
    @console_process_info = DL::PROCESS_INFORMATION.malloc
    @console_process_info.to_ptr[0, DL::PROCESS_INFORMATION.size] = "\x00".b * DL::PROCESS_INFORMATION.size
    startup_info = DL::STARTUPINFOW.malloc
    (startup_info.to_ptr + 0)[0, DL::STARTUPINFOW.size] = "\x00".b * DL::STARTUPINFOW.size
    startup_info.cb = DL::STARTUPINFOW.size
    if ENV['YAMATANOOROTI_SHOW_WINDOW']
      startup_info.dwFlags = DL::STARTF_USESHOWWINDOW
      startup_info.wShowWindow = DL::SW_SHOWNOACTIVE
    else
      startup_info.dwFlags = DL::STARTF_USESHOWWINDOW
      startup_info.wShowWindow = DL::SW_HIDE
    end

    r = DL.CreateProcessW(
      Fiddle::NULL, converted_command,
      Fiddle::NULL, Fiddle::NULL,
      0,
      DL::CREATE_NEW_CONSOLE | DL::CREATE_UNICODE_ENVIRONMENT,
      Fiddle::NULL, Fiddle::NULL,
      startup_info, @console_process_info
    )
    error_message(r, 'CreateProcessW')

    # wait for console startup complete
    8.times do |n|
      break if in_child { true }
      sleep 0.02 * 2**n
    end

    in_child do |conin, conout|
      DL.set_console_window_size(conout, height, width)
    end
  end

  private def mb2wc(str)
    size = DL.MultiByteToWideChar(65001, 0, str, str.bytesize, '', 0)
    converted_str = String.new("\x00" * (size * 2), encoding: 'ASCII-8BIT')
    DL.MultiByteToWideChar(65001, 0, str, str.bytesize, converted_str, size)
    converted_str
  end

  private def wc2mb(str)
    size = DL.WideCharToMultiByte(65001, 0, str, str.bytesize / 2, '', 0, 0, 0)
    converted_str = "\x00" * size
    DL.WideCharToMultiByte(65001, 0, str, str.bytesize / 2, converted_str, converted_str.bytesize, 0, 0)
    converted_str
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

  class TargetProcessManager
    def initialize(command)
      @errin, err = IO.pipe
      @pid = spawn(command, {in: ["conin$", File::RDWR | File::BINARY], out: ["conout$", File::RDWR | File::BINARY], err: err})
      err.close
      @closed = false
      @status = nil
      @q = Thread::Queue.new
      @t = Thread.new do
        err = @errin.gets
        @q << err if err
      end
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

  private def launch(command)
    target = in_child do
      TargetProcessManager.new(command)
    end
    sleep @wait
    target
  end

  private def setup_cp(cp)
    if cp
      @codepage_success_p = in_child { system("chcp #{Integer(cp)} > NUL") }
    end
  end

  private def codepage_success?
    @codepage_success_p
  end

  private def error_message(r, method_name)
    return if not r.zero?
    err = DL.GetLastError
    string = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
    DL.FormatMessage(
      DL::FORMAT_MESSAGE_ALLOCATE_BUFFER | DL::FORMAT_MESSAGE_FROM_SYSTEM,
      Fiddle::NULL,
      err,
      0x0,
      string,
      0,
      Fiddle::NULL
    )
    log "ERROR(#{method_name}): #{err.to_s}: #{string.ptr.to_s.force_encoding("locale")}"
    DL.LocalFree(string)
  end

  private def log(str)
    $stderr.puts str
  end

  def write(str)
    records = Fiddle::Pointer.malloc(DL::INPUT_RECORD_WITH_KEY_EVENT.size * str.size * 2, DL::FREE)
    str.chars.each_with_index do |c, i|
      c = "\r" if c == "\n"
      byte = c.getbyte(0)
      if c.bytesize == 1 and byte.allbits?(0x80) # with Meta key
        c = (byte ^ 0x80).chr
        control_key_state = DL::LEFT_ALT_PRESSED
      else
        control_key_state = 0
      end
      record_index = i * 2
      r = DL::INPUT_RECORD_WITH_KEY_EVENT.new(records + DL::INPUT_RECORD_WITH_KEY_EVENT.size * record_index)
      set_input_record(r, c, true, control_key_state)
      record_index = i * 2 + 1
      r = DL::INPUT_RECORD_WITH_KEY_EVENT.new(records + DL::INPUT_RECORD_WITH_KEY_EVENT.size * record_index)
      set_input_record(r, c, false, control_key_state)
    end
    written_size = Fiddle::Pointer.malloc(Fiddle::SIZEOF_DWORD, DL::FREE)
    in_child do |conin, conout|
      r = DL.WriteConsoleInputW(conin, records, str.size * 2, written_size)
      error_message(r, 'WriteConsoleInput')

      n = Fiddle::Pointer.malloc(Fiddle::SIZEOF_DWORD, DL::FREE)
      loop do
        sleep 0.02
        r = DL.GetNumberOfConsoleInputEvents(conin, n)
        error_message(r, 'GetNumberOfConsoleInputEvents')
        break if n.to_str.unpack1("L") == 0
        @target.sync
        break if @target.closed?
      end
    end
  end

  private def set_input_record(r, c, key_down, control_key_state)
    begin
      code = c.unpack('U').first
    rescue ArgumentError
      code = c.bytes.first
    end
    r.EventType = DL::KEY_EVENT
    r.bKeyDown = key_down ? 1 : 0
    r.wRepeatCount = 1
    r.wVirtualKeyCode = DL.VkKeyScanW(code)
    r.wVirtualScanCode = DL.MapVirtualKeyW(code, 0)
    r.UnicodeChar = code
    r.dwControlKeyState = control_key_state
  end

  private def free_resources
    h_snap = DL.CreateToolhelp32Snapshot(DL::TH32CS_SNAPPROCESS, 0)
    pe = DL::PROCESSENTRY32W.malloc
    pe.to_ptr[0, DL::PROCESSENTRY32W.size] = "\x00" * DL::PROCESSENTRY32W.size
    pe.dwSize = DL::PROCESSENTRY32W.size
    r = DL.Process32FirstW(h_snap, pe)
    error_message(r, "Process32First")
    process_table = {}
    loop do
      process_table[pe.th32ParentProcessID] ||= []
      process_table[pe.th32ParentProcessID] << pe.th32ProcessID
      break if DL.Process32NextW(h_snap, pe).zero?
    end
    process_table[DL.GetCurrentProcessId].each do |child_pid|
      kill_process_tree(process_table, child_pid)
    end
    r = DL.CloseHandle(h_snap)
    error_message(r, "CloseHandle(h_snap)")
    r = DL.CloseHandle(@console_process_info.hProcess)
    error_message(r, "CloseHandle(hProcess)")
    r = DL.CloseHandle(@console_process_info.hThread)
    error_message(r, "CloseHandle(hThread)")
  end

  private def kill_process_tree(process_table, pid)
    process_table[pid]&.each do |child_pid|
      kill_process_tree(process_table, child_pid)
    end
    h_proc = DL.OpenProcess(DL::PROCESS_ALL_ACCESS, 0, pid)
    if (h_proc.to_i != 0)
      r = DL.TerminateProcess(h_proc, 0)
      error_message(r, "TerminateProcess")
      r = DL.CloseHandle(h_proc)
      error_message(r, "CloseHandle")
    end
  end

  def close
    @target.sync
    sleep @wait if !@target.closed?
    # read first before kill the console process including output
    @result = retrieve_screen

    free_resources
    @target.sync
    @target.ensure_close
  end

  private def retrieve_screen(top_of_buffer: false)
    top, bottom = in_child do |conin, conout|
      csbi = DL.get_console_screen_buffer_info(conout)
      if top_of_buffer
        [0, csbi.Bottom]
      else
        [csbi.Top, csbi.Bottom]
      end
    end

    buffer_chars = @width * 8
    buffer = Fiddle::Pointer.malloc(Fiddle::SIZEOF_SHORT * buffer_chars, DL::FREE)
    n = Fiddle::Pointer.malloc(Fiddle::SIZEOF_DWORD, DL::FREE)
    lines = in_child do |conin, conout|
      (top..bottom).map do |y|
        r = DL.ReadConsoleOutputCharacterW(conout, buffer, @width, y << 16, n)
        error_message(r, "ReadConsoleOutputCharacterW")
        if r != 0
          wc2mb(buffer[0, n.to_str.unpack1("L") * 2]).gsub(/ *$/, "")
        else
          ""
        end
      end
    end
    lines
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

  def start_terminal(height, width, command, wait: 1, startup_message: nil)
    start_terminal_with_cp(height, width, command, wait: wait, startup_message: startup_message)
  end

  def start_terminal_with_cp(height, width, command, wait: 1, startup_message: nil, codepage: nil)
    @height = height
    @width = width
    @wait = wait * (ENV['YAMATANOOROTI_WAIT_RATIO']&.to_f || 1.0)
    @result = nil
    setup_console(height, width)
    setup_cp(codepage)
    @target = launch(command.map{ |c| quote_command_arg(c) }.join(' '))
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
        screen = retrieve_screen(top_of_buffer: true).join("\n").sub(/\n*\z/, "\n")
        break if check_startup_message.(screen)
        @target.sync
        break if @target.closed?
        sleep @wait
      end
    end
  end
end

class Yamatanooroti::WindowsTestCase < Test::Unit::TestCase
  include Yamatanooroti::WindowsTestCaseModule
end
