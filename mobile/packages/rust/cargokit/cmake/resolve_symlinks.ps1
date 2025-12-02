function Resolve-Symlinks {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $Path
    )

    [string] $separator = '/'
    [string[]] $parts = $Path.Split($separator)

    [string] $realPath = ''
    foreach ($part in $parts) {
        if ($realPath -and !$realPath.EndsWith($separator)) {
            $realPath += $separator
        }

        $realPath += $part.Replace('\', '/')

        # The slash is important when using Get-Item on Drive letters in pwsh.
        if (-not($realPath.Contains($separator)) -and $realPath.EndsWith(':')) {
            $realPath += '/'
        }

        $item = Get-Item $realPath
        if ($item.LinkTarget) {
            $realPath = $item.LinkTarget.Replace('\', '/')
        }
    }
    $realPath
}

$path = Resolve-Symlinks -Path $args[0]
Write-Host $path
