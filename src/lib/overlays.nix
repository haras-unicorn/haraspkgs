{ lib, selfLib, ... }:

{
  self.lib.overlays = {
    matching =
      dep: name:
      let
        length = builtins.stringLength dep;
        isRegex =
          length >= 2 && builtins.substring 0 1 dep == "/" && builtins.substring (length - 1) 1 dep == "/";
      in
      if isRegex then
        builtins.match (builtins.substring 1 (length - 2) dep) name != null
      else
        dep == name;

    directDeps =
      overlays: attr:
      let
        attrs = builtins.attrNames overlays;
        names = builtins.map (overlay: overlay.name) (builtins.attrValues overlays);
        name = overlays.${attr}.name;
        deps = overlays.${attr}.deps;
        undefined = builtins.filter (
          dep: !(builtins.any (candidate: selfLib.overlays.matching dep candidate) names)
        ) deps;
      in
      assert lib.assertMsg (undefined == [ ]) (
        "Dependencies ${builtins.concatStringsSep ", " undefined} of overlay ${name} are undefined"
      );
      builtins.filter (
        candidate: builtins.any (dep: selfLib.overlays.matching dep overlays.${candidate}.name) deps
      ) attrs;

    transitiveDeps =
      overlays: attr:
      let
        go =
          current: visited:
          assert lib.assertMsg (!(builtins.elem current visited)) (
            "Cycle in overlays: ${builtins.concatStringsSep " -> " (visited ++ [ current ])}"
          );
          let
            deps = selfLib.overlays.directDeps overlays current;
          in
          lib.unique (deps ++ lib.concatMap (dep: go dep (visited ++ [ current ])) deps);
      in
      go attr [ ];

    composeOverlay =
      overlays: selected:
      let
        attrs = lib.unique (
          builtins.attrNames selected
          ++ builtins.concatMap (selfLib.overlays.transitiveDeps overlays) (builtins.attrNames selected)
        );

        attrOverlays = builtins.map (attr: { inherit attr; } // overlays.${attr}) attrs;

        # cspell:ignore toposort
        sorted = lib.toposort (
          a: b: builtins.any (dep: selfLib.overlays.matching dep a.name) b.deps
        ) attrOverlays;
      in
      assert lib.assertMsg (sorted ? result) (
        let
          cycle = builtins.concatStringsSep " -> " (builtins.map ({ name, ... }: name) sorted.loops);
        in
        "Cycle in overlays: ${cycle}"
      );
      lib.composeManyExtensions (builtins.map ({ value, ... }: value) sorted.result);

    composeOverlayAttrs =
      overlays: selected:
      builtins.mapAttrs (
        name: overlay: selfLib.overlays.composeOverlay overlays { ${name} = overlay; }
      ) selected;

    makeUndefinedDepsAssertion =
      overlays:
      let
        attrs = builtins.attrNames overlays;
        undefined = lib.filterAttrs (
          _:
          { deps, ... }:
          deps != [ ]
          && builtins.any (
            dep: !(builtins.any (candidate: selfLib.overlays.matching dep overlays.${candidate}.name) attrs)
          ) deps
        ) overlays;
        message = builtins.concatStringsSep "; " (
          lib.mapAttrsToList (
            attr:
            { deps, ... }:
            "${
              builtins.concatStringsSep ", " (
                builtins.filter (
                  dep: !(builtins.any (candidate: selfLib.overlays.matching dep overlays.${candidate}.name) attrs)
                ) deps
              )
            } -> ${overlays.${attr}.name}"
          ) undefined
        );
      in
      {
        assertion = undefined == { };
        message =
          if undefined == { } then
            "All overlay dependencies are defined"
          else
            "Dependencies ${message} of overlays are undefined";
      };

    namespaceOverlay = namespace: overlay: final: prev: {
      ${namespace} = (prev.${namespace} or { }) // (overlay final prev);
    };

    overlayAttrs = overlays: builtins.mapAttrs (_: value: value.value) (overlays);

    overlayList = overlays: builtins.map (value: value.value) (builtins.attrValues overlays);

    makeOverlayAttrs =
      namespace: overlays: filter:
      (builtins.mapAttrs (_: composed: selfLib.overlays.namespaceOverlay namespace composed) (
        selfLib.overlays.composeOverlayAttrs overlays (filter overlays)
      ))
      // {
        default = selfLib.overlays.namespaceOverlay namespace (
          selfLib.overlays.composeOverlay overlays (filter overlays)
        );
      };

    makeOverlayResult =
      pkgs: namespace: overlays:
      let
        result = (pkgs.appendOverlays overlays).${namespace};
        packages = lib.filterAttrs (_: lib.isDerivation) result;
        other = lib.filterAttrs (_: value: !(lib.isDerivation value)) result;
      in
      {
        inherit packages other;
        apps =
          builtins.mapAttrs
            (_: value: {
              type = "app";
              program = lib.getExe value;
              meta = value.meta;
            })
            (
              lib.filterAttrs (
                _: value:
                value ? meta
                && value.meta ? mainProgram
                && builtins.isString value.meta.mainProgram
                && value.meta ? description
                && builtins.isString value.meta.description
              ) packages
            );
      };
  };
}
