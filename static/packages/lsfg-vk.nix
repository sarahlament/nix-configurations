{
  lib,
  fetchFromGitHub,
  cmake,
  vulkan-headers,
  llvmPackages,
  qt6,
}:
llvmPackages.stdenv.mkDerivation rec {
  pname = "lsfg-vk";
  version = "2.0.0-dev";

  src = fetchFromGitHub {
    owner = "PancakeTAS";
    repo = "lsfg-vk";
    tag = "v${version}";
    hash = "sha256-SDZXT+eYkOPr/qqZgCip9YSSf6SWwuvv1Y20+hlqGCw=";
    fetchSubmodules = true;
  };

  postInstall = ''
    substituteInPlace $out/share/vulkan/implicit_layer.d/VkLayer_LSFGVK_frame_generation.json \
      --replace-fail "liblsfg-vk-layer.so" "$out/lib/liblsfg-vk-layer.so"
  '';

  nativeBuildInputs = [
    llvmPackages.clang-tools
    llvmPackages.libllvm
    qt6.qtbase
    qt6.qtdeclarative
    cmake
  ];

  buildInputs = [
    vulkan-headers
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DLSFGVK_BUILD_VK_LAYER=On"
    "-DLSFGVK_BUILD_CLI=On"
    "-DLSFGVK_BUILD_UI=On"
    "-DLSFGVK_INSTALL_XDG_FILES=On"
  ];
  dontWrapQtApps = true;

  meta = {
    description = "Vulkan layer for frame generation (Requires owning Lossless Scaling)";
    homepage = "https://github.com/PancakeTAS/lsfg-vk/";
    changelog = "https://github.com/PancakeTAS/lsfg-vk/releases/tag/${src.tag}";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = [
      {
        email = "sarah@lament.gay";
        github = "sarahlament";
        githubId = 4612427;
        name = "Sarah Lament";
      }
    ];
  };
}
