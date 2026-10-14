{
  description = "A standard devShell that drops into a highly isolated Bubblewrap environment for an AI agent";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    zm_pixi_repo.url = "github:zombiemaker/nix-zm_pixi";
    zm_go_repo.url = "github:zombiemaker/nix-zm_go";
    zm_opencode_repo.url = "github:zombiemaker/nix-zm_opencode";
  };

  outputs = { 
    self, 
    nixpkgs, 
    zm_pixi_repo,
    zm_go_repo,
    zm_opencode_repo
  }:

  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    zm_pixi = zm_pixi_repo.v0_75_0.machine_code.x86_64.linux.musl_libc;
    zm_go = zm_go_repo.v1_27_0.machine_code.x86_64.linux.gnu_libc;    
    
    agentToolsOs = [
      pkgs.which
      pkgs.binutils # readelf
      pkgs.coreutils
      pkgs.iputils
      pkgs.procps
      pkgs.net-tools
      pkgs.dig
      pkgs.strace
      pkgs.lsof
      pkgs.file
    ];

    agentToolsFileSystem = [];

    agentToolsSecurity = [
      pkgs.cacert
      pkgs.gnutls
      pkgs.openssl
      pkgs.bubblewrap
    ];

    agentToolsClients = [
      pkgs.wget
      pkgs.curl
      pkgs.git
    ];

    agentToolsText = [
      pkgs.gnugrep
      pkgs.ast-grep
      pkgs.ripgrep
      pkgs.jq
      pkgs.yq
      pkgs.xmlstarlet
      pkgs.tree-sitter
      pkgs.ctags
      pkgs.gawk
      pkgs.gnused
      pkgs.fd
      pkgs.bat
      pkgs.delta
      pkgs.tree
    ];

    agentToolsImage = [
      pkgs.graphiz
      pkgs.imagemagick
    ];

    agentToolsAudio = [
      pkgs.ffmpeg
    ];

    agentToolsEnvPackages = [
      pkgs.mamba-cpp
      pkgs.micromamba
      pkgs.gnutar
      pkgs.nuget
      zm_pixi
    ];

    agentToolsDataStore = [
      pkgs.duckdb
      pkgs.sqlite
      pkgs.ladybugdb
      # rocksdb?
    ];

    agentToolsShellTask = [
      pkgs.gnumake
    ];

    agentToolsCodeStackGnuBash = [
      pkgs.bashInteractive
      pkgs.shellcheck
    ];

    agentToolsCodeStackPowerShell = [
      pkgs.powershell
    ];

    agentToolsCodeStackC = [
      pkgs.cmake
      pkgs.gcc
      pkgs.clang_22
      pkgs.clang-tools
    ];

    agentToolsCodeStackCpp = [
      pkgs.cmake
      pkgs.gcc
      pkgs.clang_22
      pkgs.clang-tools
    ];

    agentToolsCodeStackRust = [];

    agentToolsCodeStackMojo = [
      zm_pixi
    ];

    agentToolsCodeStackGo = [
      pkgs.tinygo
      zm_go
    ];

    agentToolsCodeStackJava = [
      pkgs.maven
    ];

    agentToolsCodeStackDotNetCSharp = [
      pkgs.nuget
    ];

    agentToolsCodeStackJavaScript = [];

    agentToolsCodeStackJavaScriptWebBrowser = [];
    
    agentToolsCodeStackJavaScriptNodejs = [
      pkgs.nodejs
    ];

    agentToolsCodeStackJavaScriptDeno = [];
    agentToolsCodeStackJavaScriptBun = [];
    agentToolsCodeStackPython = [
      pkgs.python314
      pkgs.python314Packages.pip
      pkgs.uv
      pkgs.ruff
      zm_pixi
    ];

    agentToolsCodeStackR = [];
    agentToolsCodeStackRuby = [];
    agentToolsCodeStackLua = [];
    agentToolsCodeStackElixer = [];
    
    agentToolsCodeStackWasm = [
      pkgs.wasm-tools
    ];

    agentToolsCodeStackWasmWebBrowser = [];
    
    agentToolsCodeStackWasmWasi = [
      pkgs.wit-bindgen
      pkgs.wasmtime
      pkgs.wasmer
      pkgs.wkg
    ];

    # ACTION: Select derivations groups to make available to AI agent harness
    agentToolsSelected = agentToolsOs ++
      agentToolsShellTask ++
      agentToolsSecurity ++
      agentToolsClients ++
      agentToolsText ++
      agentToolsCodeStackGnuBash ++ 
      agentToolsCodeStackPowerShell ++
      agentToolsCodeStackC ++
      agentToolsCodeStackGo ++
      agentToolsCodeStackPython;

    ###############################################################################
    # NixOS-Native Linux ELF
    ###############################################################################
    zm_opencode_linux_nixos = zm_opencode_repo.v2_0_26.machine_code.x86_64.linux_nixos.gnu_libc;

    # Define the collection of tool derivations the AI Agent is allowed to use
    agentToolsLinuxNixOs = agentToolsSelected ++
      [ zm_opencode_linux_nixos ];

    agentClosureLinuxNixOs = pkgs.closureInfo { rootPaths = agentToolsLinuxNixOs; };

    # Build a GNU Bash script that provisions the bwrap layers and spawns an interactive containerized bash
    bwrapShellWrapperLinuxNixOs = pkgs.writeShellScriptBin "containerized-agent-linux_nixos" ''
      # Evaluate the list and bakes a standard space-separated Bash array definition right here
      mapfile -t NIX_STORE_PATHS < "${agentClosureLinuxNixOs}/store-paths"

      # Build the bwrap execution command
      BWRAP_ARGS=(
        --clearenv                                 # Strip malicious host environment variables
        --unshare-all                              # Unshare IPC, PID, User, UTS, and Cgroup namespaces
        --share-net                                # Safely allow network traffic for LLM API calls
        
        # Setup core filesystem structural nodes
        --proc /proc
        --dev /dev
        --tmpfs /run
        --tmpfs /tmp
        --tmpfs /nix/store
        --dir /bin
        --dir /home/app_runner
        --ro-bind /etc/resolv.conf /etc/resolv.conf
        --ro-bind /etc/ssl/certs /etc/ssl/certs
        --setenv TERM "''${TERM:-xterm-256color}"
        --setenv HOME "/home/app_runner"
        --setenv TEMP "/tmp"
        --setenv TEMPDIR "/tmp"
        --setenv TMP "/tmp"
        --setenv TMPDIR "/tmp"
        
        # Mount our isolated workspace explicitly as Read/Write
        --dir /workspace
        --bind ./process /workspace/process
        --bind ./product /workspace/product
        --chdir /workspace
      )

      # Iteratively mount the exact Nix Store dependencies required
      for path in "''${NIX_STORE_PATHS[@]}"; do
        BWRAP_ARGS+=(--ro-bind "$path" "$path")
      done

      # Symlink our isolated bash into the container's virtual environment
      BWRAP_ARGS+=(--symlink "${pkgs.bashInteractive}/bin/bash" /bin/bash)
      BWRAP_ARGS+=(--symlink "${pkgs.bashInteractive}/bin/bash" /bin/sh)

      # Set a clear prompt indicator and ensure the tools are injected into the agent's PATH
      CONTAINER_PATH="${pkgs.lib.makeBinPath agentToolsLinuxNixOs}:/bin"
      BWRAP_ARGS+=(--setenv PATH "''${CONTAINER_PATH}")

      # DEBUG printing PATH
      printf "CONTAINER_PATH env var paths:\n"
      printf "\t%b\n" "''${CONTAINER_PATH//:/\\n\\t}"

      # Shell prompt
      CONTAINER_PS1="\[\e[0;36m\][🤖 container]\[\e[38;5;200m\]\w\n\[\e[0;33m\]\$ "
      BWRAP_ARGS+=(--setenv PS1 "''${CONTAINER_PS1}")

      # DEBUG printing bwrap args
      echo "BWRAP_ARGS = "
      printf "\t%s\n" "''${BWRAP_ARGS[@]}"

      # Spawn Bubblewrap and enter an interactive shell inside the sandbox
      # NOTE: Evaluated directly by Nix for bwrap, and escaped with ''' for the Bash array expansion
      echo "🛡️  Starting Bubblewrap container"
      ${pkgs.bubblewrap}/bin/bwrap "''${BWRAP_ARGS[@]}" "''${TARGET_BIN_BWRAP_ARGS[@]}" "${pkgs.bashInteractive}/bin/bash"
    '';

  
  ###############################################################################
  # Traditional Linux ELF & nix-ld Shimmed
  ###############################################################################
  zm_opencode_linux = zm_opencode_repo.v2_0_26.machine_code.x86_64.linux.gnu_libc;
  
  # Define the collection of tool derivations the AI Agent is allowed to use
  agentToolsLinux = agentToolsSelected ++
    [ zm_opencode_linux ];

  # Create a closure path containing the store paths of ALL dependencies
  agentClosureLinux = pkgs.closureInfo { rootPaths = agentToolsLinux; };

  # Build a GNU Bash script that provisions the bwrap layers and spawns an interactive containerized bash
  bwrapShellWrapperLinux = pkgs.writeShellScriptBin "containerized-agent-linux" ''
    # Evaluate the list and bakes a standard space-separated Bash array definition right here
    mapfile -t NIX_STORE_PATHS < "${agentClosureLinux}/store-paths"

    # Build the bwrap execution command
    BWRAP_ARGS=(
      --clearenv                                 # Strip malicious host environment variables
      --unshare-all                              # Unshare IPC, PID, User, UTS, and Cgroup namespaces
      --share-net                                # Safely allow network traffic for LLM API calls
      
      # Setup core filesystem structural nodes
      --proc /proc
      --dev /dev
      --tmpfs /run
      --tmpfs /tmp
      --tmpfs /nix/store
      --dir /bin
      --dir /home/app_runner
      --ro-bind /etc/resolv.conf /etc/resolv.conf
      --ro-bind /etc/ssl/certs /etc/ssl/certs
      --setenv TERM "''${TERM:-xterm-256color}"
      --setenv HOME "/home/app_runner"
      --setenv TEMP "/tmp"
      --setenv TEMPDIR "/tmp"
      --setenv TMP "/tmp"
      --setenv TMPDIR "/tmp"
      
      # Mount our isolated workspace explicitly as Read/Write
      --dir /workspace
      --bind ./process /workspace/process
      --bind ./product /workspace/product
      --chdir /workspace
    )

    # Iteratively mount the exact Nix Store dependencies required
    for path in "''${NIX_STORE_PATHS[@]}"; do
      BWRAP_ARGS+=(--ro-bind "$path" "$path")
    done

    # Symlink our isolated bash into the container's virtual environment
    BWRAP_ARGS+=(--symlink "${pkgs.bashInteractive}/bin/bash" /bin/bash)
    BWRAP_ARGS+=(--symlink "${pkgs.bashInteractive}/bin/bash" /bin/sh)

    # Set a clear prompt indicator and ensure the tools are injected into the agent's PATH
    CONTAINER_PATH="${pkgs.lib.makeBinPath agentToolsLinux}:/bin"
    BWRAP_ARGS+=(--setenv PATH "''${CONTAINER_PATH}")

    # DEBUG printing PATH
    printf "CONTAINER_PATH env var paths:\n"
    printf "\t%b\n" "''${CONTAINER_PATH//:/\\n\\t}"

    # Shell prompt
    CONTAINER_PS1="\[\e[0;36m\][🤖 container]\[\e[38;5;200m\]\w\n\[\e[0;33m\]\$ "
    BWRAP_ARGS+=(--setenv PS1 "''${CONTAINER_PS1}")

    ############################################################################
    # Get all dependencies for OpenCode
    ############################################################################

    TARGET_BIN="${zm_opencode_linux}/bin/opencode"
    mapfile -t TARGET_BIN_NIX_STORE_PATHS < <(ldd "$TARGET_BIN" 2>/dev/null | \
      grep -o '/nix/store/[^/]*' | \
      sort -u)  

    LINKER_STORE_PATH=$(readlink -f /lib64/ld-linux-x86-64.so.2 | grep -o '/nix/store/[^/]*')
    echo "LINKER_STORE_PATH = $LINKER_STORE_PATH"
    TARGET_BIN_NIX_STORE_PATHS+=("''${LINKER_STORE_PATH}")

    TARGET_BIN_BWRAP_ARGS=()
    for path in ''${TARGET_BIN_NIX_STORE_PATHS[@]}; do
      echo "TARGET_BIN_NIX_STORE_PATHS item: $path"
      TARGET_BIN_BWRAP_ARGS+=("--ro-bind" "$path" "$path")
    done

    if [ -n "''${NIX_LD:-}" ]; then
      echo "NIX_LD is pointing to: $NIX_LD"
      
      # Extract the parent Nix store directory of the fallback linker
      NIX_LD_DIR=$(readlink "$NIX_LD" | grep -o '/nix/store/[^/]*')
      
      # Append this directory to your Bubblewrap mount arguments array
      TARGET_BIN_BWRAP_ARGS+=("--ro-bind" "$NIX_LD_DIR" "$NIX_LD_DIR")
    fi

    # 7. Also, parse and bind everything inside NIX_LD_LIBRARY_PATH
    if [ -n "''${NIX_LD_LIBRARY_PATH:-}" ]; then
        # Split the colon-separated paths and bind each folder
        IFS=':' read -ra PATHS <<< "''${NIX_LD_LIBRARY_PATH}"
        for p in "''${PATHS[@]}"; do
          if [ -d "$p" ]; then
            TARGET_BIN_BWRAP_ARGS+=("--ro-bind" "$p" "$p")
          fi
        done
    fi

    TARGET_BIN_BWRAP_ARGS+=("--ro-bind" "/lib64" "/lib64")
    TARGET_BIN_BWRAP_ARGS+=("--setenv" "LD_LIBRARY_PATH" "''${LD_LIBRARY_PATH}")

    echo "TARGET_BIN_BWRAP_ARGS = "
    printf "\t%s\n" "''${TARGET_BIN_BWRAP_ARGS[@]}"

    ############################################################################

    # DEBUG printing bwrap args
    echo "BWRAP_ARGS = "
    printf "\t%s\n" "''${BWRAP_ARGS[@]}"

    # Spawn Bubblewrap and enter an interactive shell inside the sandbox
    # NOTE: Evaluated directly by Nix for bwrap, and escaped with ''' for the Bash array expansion
    echo "🛡️  Starting Bubblewrap container"
    ${pkgs.bubblewrap}/bin/bwrap "''${BWRAP_ARGS[@]}" "''${TARGET_BIN_BWRAP_ARGS[@]}" "${pkgs.bashInteractive}/bin/bash"
  '';

  in {
    devShells.x86_64 = {
      linux_nixos = pkgs.mkShell {
        name = "containerized-opencode-linux_nixos";
        
        # This script runs instantly upon invoking `nix develop`
        shellHook = ''
          echo "📦 Initializing isolated AI workspace..."
          exec ${bwrapShellWrapperLinuxNixOs}/bin/containerized-agent-linux_nixos
        '';
      };

      linux = pkgs.mkShell {
        name = "containerized-opencode-linux";
        
        # This script runs instantly upon invoking `nix develop`
        shellHook = ''
          echo "📦 Initializing isolated AI workspace..."
          exec ${bwrapShellWrapperLinux}/bin/containerized-agent-linux
        '';
      };

      default = self.devShells.x86_64.linux_nixos;
    };
  };
}
