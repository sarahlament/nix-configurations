{
  lib,
  fetchurl,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "catppuccin-gitea";
  version = "1.0.2";

  src = fetchurl {
    url = "https://github.com/catppuccin/gitea/releases/download/v${version}/catppuccin-gitea.tar.gz";
    hash = "sha256-HP4Ap4l2K1BWP1zWdCKYS5Y5N+JcKAcXi+Hx1g6MVwc=";
  };

  dontBuild = true;
  sourceRoot = ".";
  installPhase = ''
    runHook preInstall
    mkdir -p $out/var/lib/forgejo/custom/public/assets/css
    cp *.css $out/var/lib/forgejo/custom/public/assets/css
    runHook postInstall
  '';

  meta = {
    description = "Catppuccin theme for Gitea (and forgejo)";
    homepage = "https://github.com/catppuccin/gitea";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
