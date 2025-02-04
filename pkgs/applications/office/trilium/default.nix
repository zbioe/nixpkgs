{ lib, stdenv, nixosTests, fetchurl, autoPatchelfHook, atomEnv, makeWrapper, makeDesktopItem, gtk3, libxshmfence, wrapGAppsHook }:

let
  description = "Trilium Notes is a hierarchical note taking application with focus on building large personal knowledge bases";
  desktopItem = makeDesktopItem {
    name = "Trilium";
    exec = "trilium";
    icon = "trilium";
    comment = description;
    desktopName = "Trilium Notes";
    categories = "Office";
  };

  meta = with lib; {
    inherit description;
    homepage = "https://github.com/zadam/trilium";
    license = licenses.agpl3Plus;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ fliegendewurst ];
  };

  version = "0.48.6";

  desktopSource = {
    url = "https://github.com/zadam/trilium/releases/download/v${version}/trilium-linux-x64-${version}.tar.xz";
    sha256 = "1n7gm6mwzf5yyk8cpn70029p1iiv26bypyfi42sx14yyjvlny4rm";
  };

  serverSource = {
    url = "https://github.com/zadam/trilium/releases/download/v${version}/trilium-linux-x64-server-${version}.tar.xz";
    sha256 = "0z7cbw11mqf2mfv6ixnczg2i4jcdpvryzl0521ai26gq42jyyy0r";
  };

in {

  trilium-desktop = stdenv.mkDerivation rec {
    pname = "trilium-desktop";
    inherit version;
    inherit meta;

    src = fetchurl desktopSource;

    # Fetch from source repo, no longer included in release.
    # (they did special-case icon.png but we want the scalable svg)
    # Use the version here to ensure we get any changes.
    trilium_svg = fetchurl {
      url = "https://raw.githubusercontent.com/zadam/trilium/v${version}/images/icon.svg";
      sha256 = "0sz3piskdlx267whx8r6afrdadn25bf0zmxplj1599zqkf7w7n0x";
    };


    nativeBuildInputs = [
      autoPatchelfHook
      makeWrapper
      wrapGAppsHook
    ];

    buildInputs = atomEnv.packages ++ [ gtk3 libxshmfence ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      mkdir -p $out/share/trilium
      mkdir -p $out/share/{applications,icons/hicolor/scalable/apps}

      cp -r ./* $out/share/trilium
      ln -s $out/share/trilium/trilium $out/bin/trilium

      ln -s ${trilium_svg} $out/share/icons/hicolor/scalable/apps/trilium.svg
      cp ${desktopItem}/share/applications/* $out/share/applications
      runHook postInstall
    '';

    # LD_LIBRARY_PATH "shouldn't" be needed, remove when possible :)
    preFixup = ''
      gappsWrapperArgs+=(--prefix LD_LIBRARY_PATH : ${atomEnv.libPath})
    '';

    dontStrip = true;
  };


  trilium-server = stdenv.mkDerivation rec {
    pname = "trilium-server";
    inherit version;
    inherit meta;

    src = fetchurl serverSource;

    nativeBuildInputs = [
      autoPatchelfHook
    ];

    buildInputs = [
      stdenv.cc.cc.lib
    ];

    patches = [
      # patch logger to use console instead of rolling files
      ./0001-Use-console-logger-instead-of-rolling-files.patch
    ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      mkdir -p $out/share/trilium-server

      cp -r ./* $out/share/trilium-server
      runHook postInstall
    '';

    postFixup = ''
      cat > $out/bin/trilium-server <<EOF
      #!${stdenv.cc.shell}
      cd $out/share/trilium-server
      exec ./node/bin/node src/www
      EOF
      chmod a+x $out/bin/trilium-server
    '';

    passthru.tests = {
      trilium-server = nixosTests.trilium-server;
    };
  };
}
