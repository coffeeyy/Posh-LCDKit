## todo:GPO Off - 0xFE,0x56 (low) ; GPO On - 0xFE,0x57 (HIGH)

## sample ##
# Write-LCD "tests"
# Write-LCDCommand lightON
# Write-LCDSplashScreen16x2 "TEST Splash Screen"

## command to write a heart (vaild location 1-7)
# Write-LCD -ByteArray 0xfe,0x4e,1,0x00,0x0a,0x15,0x11,0x11,0x0a,0x04,0x00
# Write-LCD -ByteArray 1

## command to Save custom character to EEPROM bank (not sure how to use it, may have bugs!?)
# 0xFE,0xC1 (follow with the location)

## command to Load custom characters from EEPROM bank , shows into the LCD's memory General Purpose Output (not sure how to use it, may have bugs!?)
# 0xFE,0xC0 (follow with the location)

# list all com ports (powershell)
# [System.IO.Ports.SerialPort]::getportnames()

## play alert by writing stream to the lcd
# $com = COM3
# $port = new-Object System.IO.Ports.SerialPort $com,9600,None,8,one
# $port.Open()
# 0..5 | foreach {0..255 |where {$_%15 -eq 0}|foreach {[byte[]]$fullcommand = 0xFE,0x99,$_ ; $port.write([byte[]]$fullCommand,0,$fullCommand.count);Start-Sleep -Milliseconds 50}}
# $port.Close()

function Write-LCD{
    param(
    [string]$String,
    [byte[]]$ByteArray
    )
    $lcd=Get-WmiObject -Class Win32_PnPEntity |where {$_.PNPDeviceID -eq 'USB\VID_239A&PID_0001\5&178FFD7B&0&1'}
    $com=((($lcd.caption -split '\(')[1]) -split '\)')[0]
    $port= new-Object System.IO.Ports.SerialPort $com,9600,None,8,one
    if ($String){
        $port.Open()
        $port.write($String)
        $port.Close()
    }
    elseif ($ByteArray){
        $port.Open()
        $port.write($ByteArray,0,$ByteArray.count)
        $port.Close()
    }
    Remove-Variable port
}

function Write-LCDCommand{
    param(
    [string]$Command,
    [byte[]]$Value
    )
    if ($Command){
        switch ($Command) {
            "Return"        {[byte[]]$fullCommand=0x0D}
            "Backspace"     {[byte[]]$fullCommand=0x08}
            "lightON"       {[byte[]]$fullCommand=0xFE,0x42,0x00}
            "lightOFF"      {[byte[]]$fullCommand=0xFE,0x46}
            "home"          {[byte[]]$fullCommand=0xFE,0x48}
            "underlineON"   {[byte[]]$fullCommand=0xFE,0x4A}
            "underlineOFF"  {[byte[]]$fullCommand=0xFE,0x4B}
            "back"          {[byte[]]$fullCommand=0xFE,0x4C}
            "forward"       {[byte[]]$fullCommand=0xFE,0x4D}
            "scrollON"      {[byte[]]$fullCommand=0xFE,0x51}
            "scrollOFF"     {[byte[]]$fullCommand=0xFE,0x52}
            "blockON"       {[byte[]]$fullCommand=0xFE,0x53}
            "blockOFF"      {[byte[]]$fullCommand=0xFE,0x54}
            "clear"         {[byte[]]$fullCommand=0xFE,0x58}
            "Contrast"      {[byte[]]$fullCommand=0xFE,0x50;$fullCommand=$fullCommand+$Value} # recommand 200
            "ContrastSave"  {[byte[]]$fullCommand=0xFE,0x91;$fullCommand=$fullCommand+$Value}
            "position"      {[byte[]]$fullCommand=0xFE,0x47;$fullCommand=$fullCommand+$Value} # columns,rows start with 1,1
            "brightness"    {[byte[]]$fullCommand=0xFE,0x99;$fullCommand=$fullCommand+$Value}
            "BrightnessSave"{[byte[]]$fullCommand=0xFE,0x98;$fullCommand=$fullCommand+$Value}
            "rgb"           {[byte[]]$fullCommand=0xFE,0xD0;$fullCommand=$fullCommand+$Value}
            "LCDsize"       {[byte[]]$fullCommand=0xFE,0xD1;$fullCommand=$fullCommand+$Value} # columns,rows
            default {$fullcommand=$false}
        }
    }
    if($fullcommand){
        $lcd=Get-WmiObject -Class Win32_PnPEntity |where {$_.PNPDeviceID -eq 'USB\VID_239A&PID_0001\5&178FFD7B&0&1'}
        $com=((($lcd.caption -split '\(')[1]) -split '\)')[0]
        $port= new-Object System.IO.Ports.SerialPort $com,9600,None,8,one
        $port.Open()
        $port.write([byte[]]$fullCommand,0,$fullCommand.count)
        $port.Close()
        Remove-Variable port
    }
}

function Write-LCDSplashScreen16x2{
    param(
    [string]$texts,
    [switch]$default
    )
    # if ($tests.length -gt 32) {write-host "write up to 32 characters (for 16x2) or up to 80 characters (for 20x4)"}
    if ($texts.length -gt 32){write-host "write up to 32 characters (for 16x2)";break}
    if ($texts){
        write-host "write : "
        write-host $texts
        write-host "to startup splash screen"
        $lcd=Get-WmiObject -Class Win32_PnPEntity |where {$_.PNPDeviceID -eq 'USB\VID_239A&PID_0001\5&178FFD7B&0&1'}
        $com=((($lcd.caption -split '\(')[1]) -split '\)')[0]
        $port= new-Object System.IO.Ports.SerialPort $com,9600,None,8,one
        $port.Open()
        # write-host $fullcommand
        [byte[]]$Command=0xFE,0x40
        $port.write([byte[]]$Command,0,$Command.count)
        $port.write($texts)
        for ($i=0;$i -le (32 - $texts.length);$i++){$port.write(" ")}
        $port.Close()
        Remove-Variable port
    }
    if ($default){
        write-host "writing default splash screen message"
        $lcd=Get-WmiObject -Class Win32_PnPEntity |where {$_.PNPDeviceID -eq 'USB\VID_239A&PID_0001\5&178FFD7B&0&1'}
        $com=((($lcd.caption -split '\(')[1]) -split '\)')[0]
        $port= new-Object System.IO.Ports.SerialPort $com,9600,None,8,one
        $port.Open()
        # write-host $fullcommand
        [byte[]]$Command=0xFE,0x40
        $port.write([byte[]]$Command,0,$Command.count)
        $port.write("USB/Serial LCD  Adafruit.com    ")
        $port.Close()
        Remove-Variable port
    }
}
