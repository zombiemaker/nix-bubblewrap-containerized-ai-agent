# NixOS + Nix + Bubblewrap Containerized OpenCode AI Agent

Experimental Bubblewrap-containerized environment for OpenCode (or any other 
AI agent harness) to go nuts in with less concern that any agent actions will
destroy your system running it.  Utilizes Nix and Nixpkgs library to provision
software for the AI agent harness to use.

## Supported Environments
- NixOS Linux machines on x86_64 machines
- Linux + Nix on x86_64 machines

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