Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$balloon = New-Object System.Windows.Forms.NotifyIcon
$balloon.Icon = [System.Drawing.SystemIcons]::Information
$balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
$balloon.BalloonTipTitle = "Trae Notification"
$balloon.BalloonTipText = "Task completed! Check the results."
$balloon.Visible = $true
$balloon.ShowBalloonTip(5000)

Start-Sleep -Seconds 6
$balloon.Dispose()
