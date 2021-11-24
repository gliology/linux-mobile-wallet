{ lib
, writeText
, callPackage
, buildUBoot
, armTrustedFirmwareAllwinner
, crustFirmware
, fetchpatch
, fetchurl
, fetchFromGitHub
, buildPackages
}:

let
  pine64Patch = rev: sha256: fetchpatch {
    inherit sha256;
    name = "pine64-${rev}.patch";
    url = "https://gitlab.com/pine64-org/u-boot/-/commit/${rev}.patch";
  };

  crustATFPatch = rev: sha256: fetchpatch {
    inherit sha256;
    name = "arm-trusted-firmware-patch-${rev}.patch";
    url = "https://github.com/crust-firmware/arm-trusted-firmware/commit/${rev}.patch";
  };

  atf = armTrustedFirmwareAllwinner.overrideAttrs(old: rec {
    version = "2.5";
    src = fetchFromGitHub {
      owner = "ARM-software";
      repo = "arm-trusted-firmware";
      rev = "v${version}";
      sha256 = "0w3blkqgmyb5bahlp04hmh8abrflbzy0qg83kmj1x9nv4mw66f3b";
    };
    patches = [
      # "allwinner: Choose PSCI states to avoid translation"
      # https://github.com/crust-firmware/arm-trusted-firmware/commit/981a0f37f9c2d8e9cdff5bf34c80c3dd7e1128ae
      (crustATFPatch "981a0f37f9c2d8e9cdff5bf34c80c3dd7e1128ae" "1d6xq22bgr5w8v1zhr94c0zymizkz20wxicgf469jl7vspirj6pb")
      # "allwinner: Simplify CPU_SUSPEND power state encoding"
      # https://github.com/crust-firmware/arm-trusted-firmware/commit/d6ebf5dab2daab8d94c5505704473f3bab3ec4ff
      (crustATFPatch "d6ebf5dab2daab8d94c5505704473f3bab3ec4ff" "043gxv0s0nx0g9099s0hbijwcjyjbsdf50nakwhs6ndcmrcc6k67")
    ];
  });
in
(buildUBoot {
  defconfig = "pinephone_defconfig";
  extraMeta.platforms = ["aarch64-linux"];
  BL31 = "${atf}/bl31.bin";
  SCP = "${crustFirmware}/scp.bin";

  filesToInstall = ["u-boot-sunxi-with-spl.bin" "u-boot.img" "u-boot.dtb"];

  # The current u-boot build doesn't know about the USB controllers.
  # When it will, ths will allow enabling usb mass storage gadget.
  #  CONFIG_USB_MUSB_GADGET=y
  #  CONFIG_CMD_USB_MASS_STORAGE=y
  extraConfig = ''
    # The default autoboot doesn't *wait*.
    # Though any input before will cancel it.
    # This is because we re-invest the 2s in our own menu.
    CONFIG_AUTOBOOT_KEYED_CTRLC=y
    CONFIG_BOOTDELAY=0
    CONFIG_REGEX=y
  '';
}).overrideAttrs(old: rec {
  version = "2021.10";
  src = fetchurl {
    url = "ftp://ftp.denx.de/pub/u-boot/u-boot-${version}.tar.bz2";
    sha256 = "1m0bvwv8r62s4wk4w3cmvs888dhv9gnfa98dczr4drk2jbhj7ryd";
  };

  patches = [
    # Enable led on boot to notify user of boot status
    # https://gitlab.com/pine64-org/u-boot/-/commit/1a72bd9f5b0d75361b0852ed515d40a47c1e9bfe
    (pine64Patch "1a72bd9f5b0d75361b0852ed515d40a47c1e9bfe" "0z6md01qcsf6xwb6hyn4cgxjz2d0dhv05k5hrqp9kwsh9yghchqq")
  ];

  postInstall = ''
    cp .config $out/build.config
  '';
  postPatch = old.postPatch + ''
    cat $extraConfigPath >> configs/$defconfig
  '';
  nativeBuildInputs = [
    (buildPackages.python3.withPackages(p: [
      p.libfdt
      p.setuptools # for pkg_resources
    ]))
  ] ++ old.nativeBuildInputs;
})
