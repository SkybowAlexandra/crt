#站点名字
$webname = "脚本测试"
#证书信息
$HostBind = 
"*:46889:yfcbsf991.qpwbjkn.top"


$Pwd = ConvertTo-SecureString -String "ubc59F6gvZMc" -Force -AsPlainText

$cer = Import-PfxCertificate -FilePath ".\SHA384withRSA_yfcbsf991.qpwbjkn.top.pfx" -CertStoreLocation Cert:\LocalMachine\My -Password $Pwd



$hostData = $HostBind -split ":"

for ($x = 0; $x -lt $hostData.Length; $x = $x + 3)
{

	New-WebBinding -Name $webname -Protocol https -Port $hostData[$x + 1] -IPAddress $hostData[$x] -HostHeader $hostData[$x + 2] -SslFlags 1
	(Get-WebBinding -Name $webname -Port $hostData[$x + 1] -Protocol "https" -IPAddress $hostData[$x] -HostHeader $hostData[$x + 2]).AddSslCertificate($cer.Thumbprint, "my")
}

