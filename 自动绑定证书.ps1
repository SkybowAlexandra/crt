#站点名字
$webname = "脚本测试"

#绑定的域名的信息
$HostBind = 
"*:44994:wvfq.pwxnntkp.top",
"*:19923:jqjh.retbhdz.top",
"*:18441:eetp.hydjqc.top",
"*:23799:ghown.lvtveqvn.top",
"*:53965:cgyg.goucwm.top",
"*:20932:rvfaze.woaziwn.top",
"*:23515:udpoi.vtgxlt.top",
"*:26486:dsns.riensck.top",
"*:29481:gtpu.ekppqlvm.top",
"*:40619:lme.xullarp.top",
"*:38774:grx.sbsmsk.top",
"*:24658:hhvw.gefczasmw.top",
"*:21650:qbaxk.ckmetbvl.top",
"*:32147:glbrb.prdenaktd.top"

#使用:分割字符串
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
    
    #存放有匹配的信息
    $FinalHashTable =@{}
    #存放无匹配的信息
    $UnmatchedHashTable = @{}

    foreach ($key in $CrtMsg.Keys) 
    {
        $matched = $false
        foreach ($value in $DirCrts)
         {
            if ($value -like "*$key*")
            {
                #有密码信息,在数组里找到了证书
                $FinalHashTable[$value] = $CrtMsg[$key]
                #标记找到匹配的证书
                $matched = $true  
            }
        }
        if (-not $matched)
        {
            # 没有找到匹配的证书，将其存储在不匹配的哈希表中
            $UnmatchedHashTable[$key] = $CrtMsg[$key]
        }

    }
    Write-Host "以下域名有密码但找不到任何证书:.... " -ForegroundColor Red
    foreach ($it in $UnmatchedHashTable.Keys)
    {
        Write-Host $it
    }

    return $FinalHashTable
}

function FindValuesNotInDictionary
{
    param (
        [array]$Array,
        [hashtable]$Dictionary
    )
    $NotInDictionary = @()
    foreach ($item in $Array)
    {
        if (-not $Dictionary.ContainsKey($item))
        {
            $NotInDictionary += $item
        }
    }
    return $NotInDictionary
}

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
    }
    catch {
        return $true  # 端口可用
    }
}




function main
{
    Write-Host "Runing ...."
    #获取当前密码本的信息,返回一个字典
    $CrtMsg = GetCrtPassMsg(".\password.txt")

    #获取当前目录的所有证书文件,返回一个数组,存放所有证书文件名
    $DirCrts = Get-PfxCertificateFileNames(".\")



    #匹配本目录证书文件，获取最终的字典,存放证书文件名和密码
    $FinalHashTable =  Crtmatch -CrtMsg $CrtMsg -DirCrts $DirCrts

    #找到有证书但是没有密码的
    $notFoundValues = FindValuesNotInDictionary -Array $DirCrts -Dictionary $FinalHashTable
    Write-Host "未找到证书密码的如下" -ForegroundColor Red
    foreach($it in $notFoundValues)
    {
        Write-Host $it
    }





    #定义一个字典保存域名和证书指纹
    $HostAndThumb = @{}

    $index=1
    Write-Host "已找到证书密码如下,导入以下证书:" -ForegroundColor Green
    $FinalHashTable.GetEnumerator()|ForEach-Object{
        
        Write-Host "id: $index  CrtName: $($_.Key)  Password: $($_.Value)"
        $index++
        #执行导入证书
        $Pwd = ConvertTo-SecureString -String $($_.Value) -Force -AsPlainText
        $cer = Import-PfxCertificate -FilePath $($_.Key) -CertStoreLocation Cert:\LocalMachine\My -Password $Pwd
        #保存证书指纹信息
        $HostAndThumb[$cer.GetName()] = $cer.Thumbprint     
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
        }
    }



    $index=1
    Write-Host "绑定站点信息如下:" -ForegroundColor Green
    for ($x = 0; $x -lt $hostData.Length; $x = $x + 3)
    {

        if([string]::IsNullOrEmpty($HostAndThumb["CN="+$hostData[$x + 2]]))
        {
            Write-Host "该绑定域名找不到证书": $hostData[$x+2]
            continue
        }
     
        #根据域名获得指纹信息
        Write-Host $index ":" $hostData[$x+2]: $HostAndThumb["CN="+$hostData[$x + 2]]
	    New-WebBinding -Name $webname -Protocol https -Port $hostData[$x + 1] -IPAddress $hostData[$x] -HostHeader $hostData[$x + 2] -SslFlags 1
	    (Get-WebBinding -Name $webname -Port $hostData[$x + 1] -Protocol "https" -IPAddress $hostData[$x] -HostHeader $hostData[$x + 2]).AddSslCertificate($HostAndThumb["CN="+$hostData[$x + 2]], "my")
        $index++
    }
    Write-Host "执行完毕" -ForegroundColor Green
}

main