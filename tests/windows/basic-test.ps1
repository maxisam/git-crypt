# tests/windows/basic-test.ps1
$ErrorActionPreference = "Stop"

# Export the built git-crypt.exe to PATH
$env:PATH = "$PWD;" + $env:PATH

# Create a temporary directory for testing
$TEST_DIR = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
Write-Host "TEST_DIR: $TEST_DIR"

New-Item -ItemType Directory -Path $TEST_DIR | Out-Null
Push-Location $TEST_DIR

try {
    # Configure git
    git config --global init.defaultBranch main
    git init
    git config user.email "fake-email@gmail.com"
    git config user.name "Fake Name"

    # Initialize git-crypt
    git crypt init

    # Set up .gitattributes
    Set-Content -Path .gitattributes -Value "*.txt filter=git-crypt diff=git-crypt"

    # Create test files
    Set-Content -Path nonempty.txt -Value "Hello, world!"

    # Add and commit files
    git add .gitattributes nonempty.txt
    git commit -m 'Add files'
    write-host "Locking files with git-crypt..."
    # Lock files
    git crypt lock

    # Verify that nonempty.txt is encrypted
    Write-Host "Current directory: $(Get-Location)"
    $nonemptyFilePath = "$TEST_DIR\nonempty.txt"
    Write-Host "nonempty.txt path: $nonemptyFilePath"

    $bytes = [System.IO.File]::ReadAllBytes($nonemptyFilePath)[0..8]

    # Convert the bytes to a string
    $headerString = [System.Text.Encoding]::ASCII.GetString($bytes)

    write-host "Header: $headerString"
    # Check if the header matches the git-crypt magic header
    if ($headerString -eq "`0GITCRYPT") {
        Write-Host "nonempty.txt is encrypted"
    } else {
        Write-Error "nonempty.txt is not encrypted"
    }

    # Unlock files
    Write-Host "Unlocking files with git-crypt..."
    git crypt unlock

    # Verify that nonempty.txt is decrypted correctly
    $content = Get-Content -Path $nonemptyFilePath
    if ($content -eq "Hello, world!") {
        Write-Host "nonempty.txt is decrypted correctly"
    } else {
        Write-Error "nonempty.txt is not decrypted correctly"
    }

} finally {
    Pop-Location
    Remove-Item -Recurse -Force $TEST_DIR
}
