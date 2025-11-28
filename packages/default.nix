# Overlay to provide custom packages
final: prev: {
  ryubing-canary = final.callPackage ./ryubing-canary {};
}
