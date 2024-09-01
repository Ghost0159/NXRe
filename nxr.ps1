param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

# Check if the provided path is a directory or a file
if (Test-Path -LiteralPath $Path -PathType Container) {
    # If it's a directory, get all .nsp and .xci files
    $files = Get-ChildItem -Path $Path -Include *.nsp, *.xci -Recurse
} elseif (Test-Path -LiteralPath $Path -PathType Leaf) {
    # If it's a file, use the single file
    $files = @($Path)
} else {
    Write-Host "The specified path does not exist or is invalid."
    exit
}

foreach ($file in $files) {
    Write-Host "Processing file: $file"

    # Generate a temporary file name to store the output of nx
    $tempOutputFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName() + ".txt")

    try {
        # Execute the 'nx' command and redirect output to the temporary file
        & nx "`"$file`"" > $tempOutputFile

        # Read the content of the temporary file
        $content = Get-Content -Path $tempOutputFile

        # Variables to store game information
        $titleName = $null
        $titleID = $null
        $version = $null
        $filePathFromOutput = $null

        # Line counter
        $lineNumber = 0

        # Loop through the file content to extract necessary information
        foreach ($line in $content) {
            $lineNumber++
            Write-Host ("Processing line {0}: {1}" -f $lineNumber, $line)  # Corrected debug output format
            
            if ($line -match 'Title Name:\s*(.+)') {
                $titleName = $matches[1].Trim()
            } elseif ($line -match 'Title ID:\s*(.+)') {
                $titleID = $matches[1].Trim()
            } elseif ($lineNumber -eq 10 -and $line -match '\s*(\d+)$') {
                # Count the number of lines and grab the version at the 10th line where it's expected
                $version = $matches[1].Trim()
            } elseif ($line -match 'Filename:\s*(.+)') {
                $filePathFromOutput = $matches[1].Trim()
            }
        }

        # Check if all necessary information is present
        if (-not $titleName) {
            Write-Host "Error: 'Title Name' not found for '$file'."
            continue
        }

        if (-not $titleID) {
            Write-Host "Error: 'Title ID' not found for '$file'."
            continue
        }

        if (-not $version) {
            Write-Host "Error: 'Version' not found for '$file'."
            continue
        }

        # Use the initially provided file path if the extracted path is null or empty
        if (-not $filePathFromOutput) {
            $filePathFromOutput = $file
        }

        # Check if the complete path is correct and if the file exists
        if (-not (Test-Path -LiteralPath $filePathFromOutput -PathType Leaf)) {
            Write-Host "The file specified in 'Filename' does not exist or is invalid: '$filePathFromOutput'."
            continue
        }

        # Define the new file name using the extracted information
        $newFileName = "$titleName [$titleID][v$version]$([System.IO.Path]::GetExtension($filePathFromOutput))"

        # Build the full path for the new file name
        $newFilePath = Join-Path -Path (Get-Item -LiteralPath $filePathFromOutput).DirectoryName -ChildPath $newFileName

        # Check if the new path already exists to avoid conflicts
        if (Test-Path -LiteralPath $newFilePath) {
            Write-Host "Error: The file '$newFilePath' already exists. Cannot rename."
            continue
        }

        # Rename the file if the new path is valid
        Rename-Item -LiteralPath $filePathFromOutput -NewName $newFilePath -Force
        Write-Output "Renamed '$filePathFromOutput' to '$newFileName'"

    } catch {
        Write-Host "Error: An exception occurred. Details: $_"
    } finally {
        # Cleanup: remove the temporary file
        if (Test-Path -LiteralPath $tempOutputFile) {
            Remove-Item -LiteralPath $tempOutputFile -Force
        }
    }
}
