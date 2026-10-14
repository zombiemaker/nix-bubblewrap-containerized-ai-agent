Write-Host "Executing post_nix_shell.ps1 Script"

function Start-PixiShell {
    Write-Host @"
To start Pixi shell with a specific Pixi environment:
    pixi shell -e name-of-pixi-env
"@

$title = "Confirmation Required"
$message = @"
Which Pixi shell environment:

0 = no Pixi shell
1 = default
2 = mojo-dev
3 = max-dev
4 = cpython-dev
"@
    $options = (0, 1, 2, 3)
    $default = 0 # Default to '0' (index 0) if the user hits Enter

    # Display the prompt and capture the choice index
    $choice = $Host.UI.PromptForChoice($title, $message, $options, $default)

    # Conditionally execute code based on the choice
    switch ($choice) {
        0 {
            Write-Host "`nNot starting Pixi shell"
        }

        1 {
            Write-Host "`nStarting Pixi shell with default environment"
            pixi shell
        }

        2 {
            Write-Host "`nStarting Pixi shell with mojo-dev environment" -ForegroundColor Green
            pixi shell -e mojo-dev
        }

        3 {
            Write-Host "`nStarting Pixi shell with max-dev environment" -ForegroundColor Green
            Write-Host @"
To start Max serve, execute 'max serve --model huggingface-model-path  --device-memory-utilization 0.65 --no-device-graph-capture'

Example: max serve --model Qwen/Qwen2.5-Coder-3B-Instruct  --device-memory-utilization 0.65 --no-device-graph-capture
"@
            pixi shell -e max-dev
        }

        4 {
            Write-Host "`nStarting Pixi shell with cpython-dev environment" -ForegroundColor Green
            pixi shell -e cpython-dev
        }
    }
}


switch ($env:name) {
    "pwsh_llvm_clang-env" {
        Write-Host "Using $($env:name) Nix Shell"
    }

    "pwsh_pixi_mojo-env" {
        Write-Host "Using $($env:name) Nix Shell"
        Write-Host "To initialize Pixi: execute 'pixi init'"
        Write-Host "To start Pixi shell: execute 'pixi shell'"

        Start-PixiShell
    }

    "pwsh_pixi_cpython-env" {
        Write-Host "Using $($env:name) Nix Shell"
        Write-Host "To initialize Pixi: execute 'pixi init'"
        Write-Host "To add Python freethreading to Pixi default environment: execute 'pixi add python-freethreading'"
        Write-Host "To add Python to Pixi default environment: execute 'pixi add python'"
        Write-Host "To start Pixi shell: execute 'pixi shell'"
        Start-PixiShell
    }

    "pwsh_rust_toolchain-env" {
        Write-Host "Using $($env:name) Nix Shell"
    }

    default {
        Write-Host "Using $($env:name) Nix Shell"
    }
}