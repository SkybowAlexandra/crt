#վ������
$webname = "�ű�����"

#�󶨵���������Ϣ
$HostBind = 
"*:46889:yfcbsf991.qpwbjkn.top",
"*:45125:fvayzsf991.xxmffei.top.pfx"

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
    #��ȡ��ǰ���뱾����Ϣ,����һ���ֵ�
    $CrtMsg = GetCrtPassMsg(".\password.txt")

    #��ȡ��ǰĿ¼������֤���ļ�,����һ������,
    $DirCrts = Get-PfxCertificateFileNames(".\")

    #ƥ�䱾Ŀ¼֤���ļ�����ȡ���յ��ֵ�
    $FinalHashTable =  Crtmatch -CrtMsg $CrtMsg -DirCrts $DirCrts


    $FinalHashTable.GetEnumerator()|ForEach-Object{
        Write-Host "CrtName: $($_.Key), Passworld: $($_.Value)"
        #ִ�е���֤��
        $Pwd = ConvertTo-SecureString -String $($_.Value) -Force -AsPlainText
        $cer = Import-PfxCertificate -FilePath $($_.Key) -CertStoreLocation Cert:\LocalMachine\My -Password $Pwd
    }

    #ִ�а�վ��
    for ($x = 0; $x -lt $hostData.Length; $x = $x + 3)
    {
	    New-WebBinding -Name $webname -Protocol https -Port $hostData[$x + 1] -IPAddress $hostData[$x] -HostHeader $hostData[$x + 2] -SslFlags 1
	    (Get-WebBinding -Name $webname -Port $hostData[$x + 1] -Protocol "https" -IPAddress $hostData[$x] -HostHeader $hostData[$x + 2]).AddSslCertificate($cer.Thumbprint, "my")
    }

}

main