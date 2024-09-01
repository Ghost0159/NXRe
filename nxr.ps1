param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

# Function to sanitize file names by removing invalid characters
function SanitizeFileName {
    param (
        [string]$fileName
    )
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    foreach ($char in $invalidChars) {
        $fileName = $fileName -replace [regex]::Escape($char), ''
    }
    return $fileName
}

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
        $fileType = $null
        $filePathFromOutput = $null

        # Loop through the file content to extract necessary information by line number
        for ($i = 0; $i -lt $content.Count; $i++) {
            $line = $content[$i]
            $lineNumber = $i + 1
            Write-Host ("Processing line {0}: {1}" -f $lineNumber, $line)  # Debug output

            switch ($lineNumber) {
                6 {
                    if ($line -match 'Title ID:\s*(\w{16})') {
                        $titleID = $matches[1].Trim()
                    }
                }
                8 {
                    if ($line -match 'Title Name:\s*(.+)') {
                        $titleName = $matches[1].Trim()
                    }
                }
                10 {
                    if ($line -match 'Version:\s*(\d+)\s*$') {
                        $version = $matches[1].Trim()
                    }
                }
                21 {
                    if ($line -match 'Type:\s*(.+)') {
                        $fileType = $matches[1].Trim()
                    }
                }
                19 {
                    if ($line -match 'Filename:\s*(.+)') {
                        $filePathFromOutput = $matches[1].Trim()
                    }
                }
            }
        }

        # Debug outputs to check extracted information
        Write-Host "Extracted Title Name: $titleName"
        Write-Host "Extracted Title ID: $titleID"
        Write-Host "Extracted Version: $version"
        Write-Host "Extracted Type: $fileType"
        Write-Host "Extracted Filename: $filePathFromOutput"

        # Determine the destination folder based on the file type
        $destinationFolder = ""
        switch ($fileType.ToLower()) {
            "update" { $destinationFolder = "updates" }
            "dlc" { $destinationFolder = "dlc" }
            "base" { $destinationFolder = "base" }
            default { 
                Write-Host "Unknown or missing file type '$fileType'. Using default directory 'others'."
                $destinationFolder = "others"
            }
        }

        # Create the destination folder inside the original file's directory
        $originalFileDirectory = (Get-Item -LiteralPath $file).Directory.FullName
        $destinationPath = Join-Path -Path $originalFileDirectory -ChildPath $destinationFolder
        if (-not (Test-Path -LiteralPath $destinationPath)) {
            New-Item -ItemType Directory -Path $destinationPath | Out-Null
        }

        # If Title Name is missing, move the file to the appropriate directory without renaming
        if (-not $titleName) {
            Write-Host "Title Name is missing. Moving the file to the '$destinationFolder' directory without renaming."
            
            # Move the file to the designated folder
            $newFilePath = Join-Path -Path $destinationPath -ChildPath (Get-Item -LiteralPath $file).Name
            Move-Item -LiteralPath $file -Destination $newFilePath -Force
            Write-Output "Moved '$file' to '$newFilePath'"
            continue
        }

        # Check if all necessary information is present for renaming
        if (-not $titleID) {
            Write-Host "Error: 'Title ID' not found for '$file'."
            continue
        }

        if (-not $version) {
            Write-Host "Error: 'Version' not found for '$file'. Defaulting to '0'."
            $version = "0"
        }

        # Use the initially provided file path if the extracted path is null or empty
        if (-not $filePathFromOutput) {
            $filePathFromOutput = $file
        }

        # Sanitize the title name for any invalid characters
        $sanitizedTitleName = SanitizeFileName -fileName $titleName

        # Define the new file name using the sanitized Title Name, Title ID, and other extracted information
        $newFileName = "$sanitizedTitleName [$titleID][v$version]$([System.IO.Path]::GetExtension($filePathFromOutput))"
        Write-Host "New file name will be: $newFileName"  # Debug output

        # Build the full path for the new file name in the destination folder
        $newFilePath = Join-Path -Path $destinationPath -ChildPath $newFileName

        Write-Host "Full new file path: $newFilePath"  # Debug output

        # Check if the new path already exists to avoid conflicts
        if (Test-Path -LiteralPath $newFilePath) {
            Write-Host "Error: The file '$newFilePath' already exists. Cannot rename."
            continue
        }

        # Move and rename the file to the new location
        Move-Item -LiteralPath $filePathFromOutput -Destination $newFilePath -Force
        Write-Output "Moved and renamed '$filePathFromOutput' to '$newFilePath'"

    } catch {
        Write-Host "Error: An exception occurred. Details: $_"
    } finally {
        # Cleanup: remove the temporary file
        if (Test-Path -LiteralPath $tempOutputFile) {
            Remove-Item -LiteralPath $tempOutputFile -Force
        }
    }
}
