
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


$certificateFileNames = Get-PfxCertificateFileNames -directory ".\"


$certificateFileNames | ForEach-Object {
    Write-Host "CrtFileNmae:$_"
}