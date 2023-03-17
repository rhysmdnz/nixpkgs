import ./make-test-python.nix ({ pkgs, ...} : {
  name = "microsoft-identity-broker";
  meta = with pkgs.lib.maintainers; {
    maintainers = [ rhysmdnz ];
  };

  nodes.machine =
    { pkgs, ... }:
    { services.intune.enable=true;
    };

  testScript = ''
    start_all()
    machine.succeed("systemctl start microsoft-identity-device-broker.service")
  '';
})
