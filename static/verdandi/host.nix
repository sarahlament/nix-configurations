{ self, ... }:
{
  imports = with self.nixosModules; [
    lanzaboote
    virtualGuest
  ];

  modules = {
    boot.efi.enable = true;
    disko.layout = "uefi-luks";
  };

  # the vTPM (Proxmox swtpm) presents over the CRB/TIS interface; its driver has
  # to be in the initrd so systemd-cryptsetup can reach the TPM to unlock the LUKS
  # root. include both - only the one the hypervisor exposes will bind.
  boot.initrd.availableKernelModules = [
    "tpm_tis"
    "tpm_crb"
  ];
}
