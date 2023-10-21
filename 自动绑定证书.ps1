#站点名字
$webname = "脚本测试"

#绑定的域名的信息
$HostBind = 
"*:46889:yfcbsf991.qpwbjkn.top",
"*:45125:fvayzsf991.xxmffei.top.pfx"

$hostData = $HostBind -split ":"




#该函数用来获取一个目录中所有的pfx证书文件
function Get-PfxCertificateFileNames
{
    param (
        [string]$directory = (Get-Location)
    )
    # 获取指定目录下所有的 .pfx 证书文件
    $certificateFiles = Get-ChildItem -Path $directory -Filter *.pfx
    # 创建一个空数组，用于存储文件名
    $certificateFileNames = @()
    # 遍历所有的 .pfx 证书文件并将文件名添加到数组中
    foreach ($file in $certificateFiles) {
        $certificateFileNames += $file.Name
    }
    return $certificateFileNames
}

#从密码本读出密码信息
function GetCrtPassMsg($Passfile)
{
    #创建一个空字典,用来证书名字和证书密码
    $CrtMsg = @{}
    #读取txt
    $lines = Get-Content -Path $Passfile
    for ($i=0 ;$i -lt $lines.Length; $i = $i+2)
    {
        #把域名信息增加和密码插入字典
        $CrtMsg[($lines[$i].Trim())] = ($lines[$i + 1].Trim())
    }
    return $CrtMsg
}





#通过证书密码本,模糊匹配某个路径下的证书,并返回一个字典
function Crtmatch
{
    param (
        [hashtable]$CrtMsg,
        [array]$DirCrts
    )
    $FinalHashTable =@{}
    foreach ($key in $CrtMsg.Keys) 
    {
        foreach ($value in $DirCrts)
         {
            if ($value -like "*$key*")
            {
                $src_value =  $CrtMsg[$key]
                $FinalHashTable[$value] = $src_value
            }
        }
    }
    return $FinalHashTable
}


function main
{
    Write-Host "Runing ...."
    #获取当前密码本的信息,返回一个字典
    $CrtMsg = GetCrtPassMsg(".\password.txt")

    #获取当前目录的所有证书文件,返回一个数组,
    $DirCrts = Get-PfxCertificateFileNames(".\")

    #匹配本目录证书文件，获取最终的字典
    $FinalHashTable =  Crtmatch -CrtMsg $CrtMsg -DirCrts $DirCrts


    $FinalHashTable.GetEnumerator()|ForEach-Object{
        Write-Host "CrtName: $($_.Key), Passworld: $($_.Value)"
        #执行导入证书
        $Pwd = ConvertTo-SecureString -String $($_.Value) -Force -AsPlainText
        $cer = Import-PfxCertificate -FilePath $($_.Key) -CertStoreLocation Cert:\LocalMachine\My -Password $Pwd
    }

    #执行绑定站点
    for ($x = 0; $x -lt $hostData.Length; $x = $x + 3)
    {
	    New-WebBinding -Name $webname -Protocol https -Port $hostData[$x + 1] -IPAddress $hostData[$x] -HostHeader $hostData[$x + 2] -SslFlags 1
	    (Get-WebBinding -Name $webname -Port $hostData[$x + 1] -Protocol "https" -IPAddress $hostData[$x] -HostHeader $hostData[$x + 2]).AddSslCertificate($cer.Thumbprint, "my")
    }

}

main