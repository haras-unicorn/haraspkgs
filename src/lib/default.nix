{ lib, inputs, ... }:

# IMPORTANT: this file is an infinite recursion landmine
# please do not edit unless you are 100% sure of what you are doing

let
  isActuallyAttrs =
    attrs:
    builtins.isAttrs attrs
    && !(lib.isFunction attrs)
    && !(lib.isDerivation attrs)
    && !(lib.isOption attrs)
    && !(lib.isOptionType attrs);

  isFlake = attrs: isActuallyAttrs attrs && attrs ? _type && attrs._type == "flake";

  isSelfModule = attrs: isActuallyAttrs attrs && attrs ? value && (attrs ? self || attrs ? flake);
in
{
  self.lib.lib = {
    inherit inputs;

    selfSubmodule = valueType: {
      options = {
        flake = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to export this value to make the flake.";
        };

        self = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to use this value to make self.";
        };

        value = lib.mkOption {
          type = valueType;
          description = "The value.";
        };
      };
    };

    makeModuleAttrs =
      selfModules:
      let
        modules = builtins.mapAttrs (_: selfModule: selfModule.value) selfModules;
      in
      modules // { default.imports = builtins.attrValues modules; };

    filterAttrsRecursiveByKey = lib.fixedPoints.fix (
      filterAttrsRecursiveByKey: key: default: attrs:
      builtins.mapAttrs
        (
          _: inner:
          if isActuallyAttrs inner && !(isFlake inner) then
            filterAttrsRecursiveByKey key default inner
          else
            inner
        )
        (
          lib.filterAttrs (
            _: inner: if isSelfModule inner then (if inner ? ${key} then inner.${key} else default) else true
          ) attrs
        )
    );

    filterAttrsRecursiveByKeys = lib.fixedPoints.fix (
      filterAttrsRecursiveByKeys: keys: attrs:
      builtins.mapAttrs
        (
          _: inner:
          if isActuallyAttrs inner && !(isFlake inner) then filterAttrsRecursiveByKeys keys inner else inner
        )
        (
          if isSelfModule attrs then
            lib.filterAttrs (key: _: !(builtins.any (candidate: key == candidate) keys)) attrs
          else
            attrs
        )
    );

    filterAttrsByKey =
      key: default: attrs:
      lib.filterAttrs (_: attrs: if attrs ? ${key} then attrs.${key} else default) attrs;

    filterAttrsByKeys =
      keys: attrs: lib.filterAttrs (key: _: !(builtins.any (candidate: key == candidate) keys)) attrs;

    selfFunctor = {
      flake = true;
      __functor =
        _:
        {
          flake ? false,
          self ? true,
          functor ? _: _,
          recursiveFunctor ? _: functor,
        }:
        {
          inherit flake self;
          __functor = recursiveFunctor;
        };
    };
  };
}
