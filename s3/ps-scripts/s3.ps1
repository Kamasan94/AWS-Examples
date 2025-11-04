function BucketExists {
    $bucket = Get-S3Bucket -BucketName $bucketName -ErrorAction SilentlyContinue
    return $null -ne $bucket
}

if(-not (BucketExists)) {
    Write-Host "Bucket doe not exist."
    New-S3Bucket -BucketName $bucketName -Region $region
} else {
    Write-Host "Bucket already exists"
}

$fileName = 'myfile.txt'
$fileContent = 'Hello world!'
Set-Content -Path $fileName -Value $fileContent
