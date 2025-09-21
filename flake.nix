{
  description = "Dev environment: Flutter + Django REST Framework + Genymotion";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Android SDK setup (API 30, build-tools 30.0.3, etc.)
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          toolsVersion = "26.1.1";
          platformToolsVersion = "34.0.5";
          buildToolsVersions = [ "30.0.3" ];
          platformVersions = [ "30" "31" "33" "34" ];

          includeEmulator = false;  # Genymotion is used instead
        };

        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          django
          djangorestframework
          requests
        ]);

      in {
        devShells.default = pkgs.mkShell {
          name = "flutter-django-genymotion-env";

          packages = with pkgs; [
            flutter
            pythonEnv
            androidComposition.androidsdk
            android-tools
            virtualbox
            genymotion
            wget
            curl
            git
            openssl
            sqlite
            openjdk17_headless  # ✅ Java 17 for sdkmanager
          ];

          shellHook = ''
            echo "=== Flutter + Django + Genymotion Dev Shell ==="
            echo "Flutter version: $(flutter --version | head -n 1)"
            echo "Python version: $(python --version)"

            # Android SDK and Java setup
            export ANDROID_HOME=${androidComposition.androidsdk}/libexec/android-sdk
            export JAVA_HOME=${pkgs.openjdk17_headless}
            export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

            # Accept licenses (will fail silently if already accepted)
            yes | sdkmanager --licenses || true
          '';
        };
      });
}

