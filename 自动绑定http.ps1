$webname = "脚本测试"

$HostBind = 
"*:19243:qgte.dorxqn.top",
"*:13087:rurw.jtbpuc.top",
"*:19328:ukvy.zsjpwd.top",
"*:11322:kkyg.xzmeue.top",
"*:12485:bqgx.quulqm.top",
"*:18396:ltwt.bedpsx.top",
"*:10500:eqll.kszrus.top",
"*:10224:gnei.dykpvm.top",
"*:12416:qosn.rgqfgn.top",
"*:18054:yiwc.iehzwu.top",
"*:1090:vibg.ksghts.top",
"*:12372:lkzd.kmokuj.top",
"*:10255:meft.zflipk.top",
"*:12947:jiyh.kvixnx.top"

$hostData = $HostBind -split ":"

#检查端口是否被占用
function Test-PortAvailability {
    param (
        [int]$Port
    )
    $endpoint = [System.Net.Sockets.TcpClient]::new()
    try {
        $endpoint.Connect("localhost", $Port)
        $endpoint.Close()
        return $false  # 端口已被占用
        exit(1) #直接结束脚本,不执行绑定
    }
    catch {
        return $true  # 端口可用
    }
}
#检查端口是否被占用
for ($x = 0; $x -lt $hostData.Length; $x = $x + 3)
{
    if(Test-PortAvailability -Port $hostData[$x+1])
    {
        Write-Host "端口" $hostData[$x + 1] "可用"
    }
    else
    {
        Write-Host "端口" $hostData[$x+1] "不可用"
		exit()
    }
}

for ($x = 0; $x -lt $hostData.Length; $x = $x + 3) {
    New-WebBinding -Name $webname -IPAddress $hostData[$x] -Port $hostData[$x + 1] -HostHeader $hostData[$x + 2]
}