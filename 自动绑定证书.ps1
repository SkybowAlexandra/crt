#վ������
$webname = "�ű�����"

#�󶨵���������Ϣ
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

#ʹ��:�ָ��ַ���
$hostData = $HostBind -split ":"




#�ú���������ȡһ��Ŀ¼�����е�pfx֤���ļ�
function Get-PfxCertificateFileNames
{
    param (
        [string]$directory = (Get-Location)
    )
    # ��ȡָ��Ŀ¼�����е� .pfx ֤���ļ�
    $certificateFiles = Get-ChildItem -Path $directory -Filter *.pfx
    # ����һ�������飬���ڴ洢�ļ���
    $certificateFileNames = @()
    # �������е� .pfx ֤���ļ������ļ�����ӵ�������
    foreach ($file in $certificateFiles) {
        $certificateFileNames += $file.Name
    }
    return $certificateFileNames
}

#�����뱾����������Ϣ
function GetCrtPassMsg($Passfile)
{
    #����һ�����ֵ�,����֤�����ֺ�֤������
    $CrtMsg = @{}
    #��ȡtxt
    $lines = Get-Content -Path $Passfile
    for ($i=0 ;$i -lt $lines.Length; $i = $i+2)
    {
        #��������Ϣ���Ӻ���������ֵ�
        $CrtMsg[($lines[$i].Trim())] = ($lines[$i + 1].Trim())
    }
    return $CrtMsg
}

#ͨ��֤�����뱾,ģ��ƥ��ĳ��·���µ�֤��,������һ���ֵ�
function Crtmatch
{
    param (
        [hashtable]$CrtMsg,
        [array]$DirCrts
    )
    
    #�����ƥ�����Ϣ
    $FinalHashTable =@{}
    #�����ƥ�����Ϣ
    $UnmatchedHashTable = @{}

    foreach ($key in $CrtMsg.Keys) 
    {
        $matched = $false
        foreach ($value in $DirCrts)
         {
            if ($value -like "*$key*")
            {
                #��������Ϣ,���������ҵ���֤��
                $FinalHashTable[$value] = $CrtMsg[$key]
                #����ҵ�ƥ���֤��
                $matched = $true  
            }
        }
        if (-not $matched)
        {
            # û���ҵ�ƥ���֤�飬����洢�ڲ�ƥ��Ĺ�ϣ����
            $UnmatchedHashTable[$key] = $CrtMsg[$key]
        }

    }
    Write-Host "�������������뵫�Ҳ����κ�֤��:.... " -ForegroundColor Red
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

#���˿��Ƿ�ռ��
function Test-PortAvailability {
    param (
        [int]$Port
    )
    $endpoint = [System.Net.Sockets.TcpClient]::new()
    try {
        $endpoint.Connect("localhost", $Port)
        $endpoint.Close()
        return $false  # �˿��ѱ�ռ��
    }
    catch {
        return $true  # �˿ڿ���
    }
}




function main
{
    Write-Host "Runing ...."
    #��ȡ��ǰ���뱾����Ϣ,����һ���ֵ�
    $CrtMsg = GetCrtPassMsg(".\password.txt")

    #��ȡ��ǰĿ¼������֤���ļ�,����һ������,�������֤���ļ���
    $DirCrts = Get-PfxCertificateFileNames(".\")



    #ƥ�䱾Ŀ¼֤���ļ�����ȡ���յ��ֵ�,���֤���ļ���������
    $FinalHashTable =  Crtmatch -CrtMsg $CrtMsg -DirCrts $DirCrts

    #�ҵ���֤�鵫��û�������
    $notFoundValues = FindValuesNotInDictionary -Array $DirCrts -Dictionary $FinalHashTable
    Write-Host "δ�ҵ�֤�����������" -ForegroundColor Red
    foreach($it in $notFoundValues)
    {
        Write-Host $it
    }





    #����һ���ֵ䱣��������֤��ָ��
    $HostAndThumb = @{}

    $index=1
    Write-Host "���ҵ�֤����������,��������֤��:" -ForegroundColor Green
    $FinalHashTable.GetEnumerator()|ForEach-Object{
        
        Write-Host "id: $index  CrtName: $($_.Key)  Password: $($_.Value)"
        $index++
        #ִ�е���֤��
        $Pwd = ConvertTo-SecureString -String $($_.Value) -Force -AsPlainText
        $cer = Import-PfxCertificate -FilePath $($_.Key) -CertStoreLocation Cert:\LocalMachine\My -Password $Pwd
        #����֤��ָ����Ϣ
        $HostAndThumb[$cer.GetName()] = $cer.Thumbprint     
    }

    #���˿��Ƿ�ռ��
    for ($x = 0; $x -lt $hostData.Length; $x = $x + 3)
    {
        if(Test-PortAvailability -Port $hostData[$x+1])
        {
            Write-Host "�˿�" $hostData[$x + 1] "����"
        }
        else
        {
            Write-Host "�˿�" $hostData[$x+1] "������"
        }
    }



    $index=1
    Write-Host "��վ����Ϣ����:" -ForegroundColor Green
    for ($x = 0; $x -lt $hostData.Length; $x = $x + 3)
    {

        if([string]::IsNullOrEmpty($HostAndThumb["CN="+$hostData[$x + 2]]))
        {
            Write-Host "�ð������Ҳ���֤��": $hostData[$x+2]
            continue
        }
     
        #�����������ָ����Ϣ
        Write-Host $index ":" $hostData[$x+2]: $HostAndThumb["CN="+$hostData[$x + 2]]
	    New-WebBinding -Name $webname -Protocol https -Port $hostData[$x + 1] -IPAddress $hostData[$x] -HostHeader $hostData[$x + 2] -SslFlags 1
	    (Get-WebBinding -Name $webname -Port $hostData[$x + 1] -Protocol "https" -IPAddress $hostData[$x] -HostHeader $hostData[$x + 2]).AddSslCertificate($HostAndThumb["CN="+$hostData[$x + 2]], "my")
        $index++
    }
    Write-Host "ִ�����" -ForegroundColor Green
}

main