using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$metadata = Invoke-RestMethod 'https://pscoretestdata.blob.core.windows.net/buildinfo/daily.json'
$release = $metadata.ReleaseTag -replace '^v'
$architecture = $Request.Query.Architecture
$blobName = $metadata.BlobName

$packageType = $Request.Query.PackageType

switch($packageType)
{
    'win-msi' {
        $packageName = "PowerShell-${release}-win-${architecture}.msi"
    }
    'win-zip' {
        $packageName = "PowerShell-${release}-win-${architecture}.zip"
    }
    'linux-tar-gz' {
        $packageName = "powershell-${release}-linux-${architecture}.tar.gz"
    }
    'macos-tar-gz' {
        $packageName = "powershell-${release}-osx-${architecture}.tar.gz"
    }
    default {
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = 500
            Body = "Unknown packageType: $packageType"
        })
        return
    }
}

$downloadURL = [uri] "https://pscoretestdata.blob.core.windows.net/${blobName}/${packageName}"
Write-Host "new url: $downloadURL"


# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = 301
    Headers = @{Location = $downloadURL}
    Body = ''
})
