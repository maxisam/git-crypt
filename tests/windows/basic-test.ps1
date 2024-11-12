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

    # Lock files
    git crypt lock

    # Verify that files are encrypted
    $nonemptyContent = Get-Content -Path nonempty.txt -Encoding Byte
    if ($nonemptyContent[0..7] -eq [byte[]](0x00,0x47,0x49,0x54,0x43,0x52,0x59,0x50)) {
        Write-Host "nonempty.txt is encrypted"
    } else {
        Write-Error "nonempty.txt is not encrypted"
    }

    # Unlock files
    git crypt unlock

    # Verify that files are decrypted
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
