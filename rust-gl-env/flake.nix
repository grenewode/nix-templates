{

  nixConfig = {
    substituters = [
      "https://nix-community.cachix.org"
      "https://rust-analyzer-flake.cachix.org"
    ];

    trusted-public-keys = [
      "rust-analyzer-flake.cachix.org-1:M0/jTcCtgtFl6/aZV4l08+JN9Zf5dHzALWrKmCXeeoU="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="

    ];
  };

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nmattia/naersk";
    rust-analyzer.url = "github:grenewode/rust-analyzer-flake";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, naersk, rust-overlay, rust-analyzer }:
    flake-utils.lib.eachDefaultSystem (system:
      let

        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };
      in let
        rust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        naersk-lib = naersk.lib."${system}".override {
          cargo = rust;
          rustc = rust;
        };

        inherit (pkgs)
          pkg-config alsa-lib udev wayland wayland-protocols libxkbcommon xorg
t           vulkan-loader;

        inherit (pkgs.lib) makeLibraryPath optional;

        buildInputs = [
          alsa-lib
          udev

          vulkan-loader

          # Wayland Support
          wayland
          wayland-protocols
          libxkbcommon

          # X11 Support
          xorg.libX11
          xorg.libXcursor
          xorg.libXi
          xorg.libXrandr
        ];
        nativeBuildInputs = [ pkg-config ];

        package = naersk-lib.buildPackage {
          root = ./.;
          inherit buildInputs nativeBuildInputs;
        };
        name = (builtins.parseDrvName package.name).name;
      in rec {
        # `nix build`
        packages.${name} = package;
        packages.default = package;
        defaultPackage = package;

        # `nix run`
        apps.${name} = flake-utils.lib.mkApp { drv = packages.default; };
        apps.default = apps.${name};
        defaultApp = apps.default;

        # `nix develop`
        devShell = (pkgs.mkShell {
          inputsFrom =  optional (builtins.pathExists ./Cargo.lock) package ;

          packages = [
            rust
            rust-analyzer.packages.${system}.rust-analyzer-nightly
            pkgs.cargo-edit
          ] ++ nativeBuildInputs ++ buildInputs;

          shellHook = let ldLibraryPath = makeLibraryPath buildInputs;
          in ''
            export LD_LIBRARY_PATH="''${LD_LIBRARY_PATH}:${ldLibraryPath}"
          '';
        });
      });
}
