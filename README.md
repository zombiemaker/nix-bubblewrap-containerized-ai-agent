# NixOS + Nix + Bubblewrap Containerized AI Agent Harness (OpenCode)

Experimental Bubblewrap-containerized environment for OpenCode (or any other 
AI agent harness) to go nuts in with less concern that any agent actions will
destroy your system running it.  Utilizes Nix and Nixpkgs library to provision
software for the AI agent harness to use.

## Supported Environments
- NixOS Linux machines on x86_64 machines
- Linux + Nix on x86_64 machines
- Visual Studio Code

## Usage
- Clone repo
- In a PowerShell session, run "init_shell.ps1" script
- Follow options

## Customization To Container Environment
To customize the programs available to the agent harness to run within the container,
edit the flake.nix file.  

- Add / change any Nix array using the "agentTools" prefix (you can use any name you want)
- Add / remove any of the agentTools arrays that are part of the "agentToolsSelected" array
- The "agentToolsSelected" array is used in the GNU Bash script that is created by the flake.

## Content In Addition To flake.nix And init_shell.ps1
The rest of the content in this repository is for an experimental implementation
of a software factory.  This can be discarded.

If you remove the `workspace_root/process` or `workspace_root/product` directories,
you will need to edit the flake.nix where it defines the BWRAP_ARGS for the workspace
directory for both the GNU Bash scripts.