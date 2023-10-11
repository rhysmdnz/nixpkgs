# Use busybox for i686-linux since it works on x86_64-linux as well.
(import ./i686-unknown-linux-gnu.nix) //

{
  bootstrapTools = ./bootstrap-tools.tar.xz;
}
