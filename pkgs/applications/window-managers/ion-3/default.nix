{ lib, stdenv, fetchurl, xlibsWrapper, lua, gettext, groff }:

stdenv.mkDerivation rec {
  pname = "ion";
  version = "3-20090110";

  src = fetchurl {
    url = "http://tuomov.iki.fi/software/dl/ion-${version}.tar.gz";
    sha256 = "1nkks5a95986nyfkxvg2rik6zmwx0lh7szd5fji7yizccwzc9xns";
  };

  buildInputs = [ xlibsWrapper lua gettext groff ];

  buildFlags = [ "LUA_DIR=${lua}" "X11_PREFIX=/no-such-path" "PREFIX=\${out}" ];

  installFlags = [ "PREFIX=\${out}" ];

  meta = with lib; {
    description = "Tiling tabbed window manager designed with keyboard users in mind";
    homepage = "http://modeemi.fi/~tuomov/ion";
    platforms = with platforms; linux;
    license = licenses.lgpl21;
    maintainers = with maintainers; [ ];
  };
}
