## debug model
$C_debug_mode = $true

## log output interval (sec)
$C_interval = 60

## wait time (msec)
$C_waittime = 40

## date format
$C_dateformat = "yyyy/MM/dd HH:mm"

## encode
$C_Encode = 'UTF8'

## output folder
$C_output_folder = "$env:temp"

## output file name
$C_output_filename = "Keystrokes_{{date_str}}.txt"

## output path
$date_str = (Get-Date).ToString("yyMMdd")
$C_output_path = Join-path $C_output_folder $C_output_filename
$C_output_path = $C_output_path.Replace("{{date_str}}", $date_str)

## exclusion list
$C_exclusion_words = @("Shift","Ctrl","Win","Alt","Left","Right","Up","Down")

## shift keys dictionary for converting
$C_shift_key_dic = @{}
$C_shift_key_dic.Add('Shift + 1', '!') #01
$C_shift_key_dic.Add('Shift + 2', '"') #02
$C_shift_key_dic.Add('Shift + 3', '#') #03
$C_shift_key_dic.Add('Shift + 4', '$') #04
$C_shift_key_dic.Add('Shift + 5', '%') #05
$C_shift_key_dic.Add('Shift + 6', '&') #06
$C_shift_key_dic.Add('Shift + 7', "'") #07
$C_shift_key_dic.Add('Shift + 8', '(') #08
$C_shift_key_dic.Add('Shift + 9', ')') #09
$C_shift_key_dic.Add('Shift + -', '=') #10
$C_shift_key_dic.Add('Shift + ^', '~') #11 FIXME
$C_shift_key_dic.Add('Shift + @', '`') #12
$C_shift_key_dic.Add('Shift + [', '{') #13
$C_shift_key_dic.Add('Shift + ]', '}') #14
$C_shift_key_dic.Add('Shift + ;', '+') #15
$C_shift_key_dic.Add('Shift + :', '*') #16
$C_shift_key_dic.Add('Shift + ,', '<') #17
$C_shift_key_dic.Add('Shift + .', '>') #18
$C_shift_key_dic.Add('Shift + /', '?') #19
$C_shift_key_dic.Add('Shift + \', '_') ##20
# $C_shift_key_dic

## symbols
$C_symbols = '!"#$%&''()-=^~@`[{;+:*]},<.>/?\_'
# $C_symbols
