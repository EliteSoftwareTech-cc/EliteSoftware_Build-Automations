Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Create-Tile {
    $tile = New-Object System.Windows.Forms.Panel
    $tile.Size = New-Object System.Drawing.Size(100, 100)
    
    $handler = [System.Windows.Forms.PaintEventHandler]{
        param($sender, $e)
        Write-Host "sender: $sender"
        Write-Host "e: $e"
        if ($e) {
            Write-Host "Has Graphics!"
        }
    }
    
    $tile.add_Paint($handler)
    return $tile
}

$f = New-Object System.Windows.Forms.Form
$f.Controls.Add((Create-Tile))

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.add_Tick({ $f.Close() })
$timer.Start()

$f.ShowDialog()
