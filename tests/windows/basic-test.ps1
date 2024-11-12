# test/basic-test.ps1
$ErrorActionPreference = "Stop"

# Export the built git-crypt.exe to PATH
$env:PATH = "$PWD;" + $env:PATH

# Create a temporary directory for testing
$TEST_DIR = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $TEST_DIR | Out-Null
Push-Location $TEST_DIR

try {
    # Configure git
    git init
    git config user.email "fake-email@gmail.com"
    git config user.name "Fake Name"
    git config --global init.defaultBranch main

    # Initialize git-crypt
    git crypt init

    # Set up .gitattributes
    Set-Content -Path .gitattributes -Value "*.txt filter=git-crypt diff=git-crypt"

    # Create test files
    Set-Content -Path nonempty.txt -Value "Hello, world!"

    # Add and commit files
    git add .gitattributes nonempty.txt
    git commit -m 'Add files'

    # Lock files
    git crypt lock

    # Verify that nonempty.txt is encrypted using Select-String
    if (Select-String -Path nonempty.txt -Pattern '\x00GITCRYPT' -SimpleMatch -Encoding Byte) {
        Write-Host "nonempty.txt is encrypted"
    } else {
        Write-Error "nonempty.txt is not encrypted"
    }

    # Unlock files
    git crypt unlock

    # Verify that nonempty.txt is decrypted correctly
    $content = Get-Content -Path nonempty.txt
    if ($content -eq "Hello, world!") {
        Write-Host "nonempty.txt is decrypted correctly"
    } else {
        Write-Error "nonempty.txt is not decrypted correctly"
    }

} finally {
    Pop-Location
    Remove-Item -Recurse -Force $TEST_DIR
}
