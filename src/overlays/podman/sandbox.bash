startPodmanSandbox() {
  if [ -z "${NIX_BUILD_TOP:-}" ] || [ -z "${NIX_LOG_FD:-}" ]; then
    return 0
  fi

  if [ "$(id -u)" -ne 0 ]; then
    echo 'podman in the nix sandbox needs requiredSystemFeatures = [ "uid-range" ]' >&2
    return 1
  fi

  local state socket
  state="$(mktemp -d "$NIX_BUILD_TOP/podman-sandbox.XXXXXX")"
  socket="$state/podman.sock"

  mkdir -p \
    "$state/home/.config/containers" "$state/run" "$state/networks" \
    "$state/cdi"
  ln -s @policy@ "$state/home/.config/containers/policy.json"
  sed "s|__STATE__|$state|g" @storageConf@ > "$state/storage.conf"
  sed "s|__STATE__|$state|g" @containersConf@ > "$state/containers.conf"

  # The spec of the host is not used, because its hooks are store paths that
  # a build does not have. This one is made from the driver the build got.
  if [ -n "@cdiHook@" ] && [ -e /dev/nvidiactl ]; then
    nvidia-ctk cdi generate \
      --format json \
      --output "$state/cdi/nvidia.json" \
      --disable-hook create-symlinks \
      --ldconfig-path @ldconfig@ \
      --library-search-path /run/opengl-driver/lib \
      --nvidia-cdi-hook-path @cdiHook@
  fi

  # Required mounts, like the GPU ones, make /run in the build owned by a user
  # this namespace does not map, and podman keeps its runtime state in /run.
  mkdir -p /run
  if [ ! -w /run ]; then
    mount -t tmpfs none /run
  fi

  # The sandbox has an empty /sys/fs/cgroup, so podman takes it for cgroups v1
  # and crun fails with "invalid file system type".
  mount -t cgroup2 none /sys/fs/cgroup
  ip link set lo up
  echo 1 > /proc/sys/net/ipv4/ip_forward

  env \
    HOME="$state/home" \
    XDG_RUNTIME_DIR="$state/run" \
    CONTAINERS_CONF="$state/containers.conf" \
    CONTAINERS_STORAGE_CONF="$state/storage.conf" \
    NETAVARK_FW=nftables \
    podman system service --time 0 "unix://$socket" \
    > "$state/service.log" 2>&1 &
  podmanSandboxPid=$!

  if ! timeout "$PODMAN_SANDBOX_START_TIMEOUT" \
    sh -c 'until [ -S "$1" ]; do sleep 0.1; done' _ "$socket"; then
    cat "$state/service.log" >&2
    return 1
  fi

  export CONTAINER_HOST="unix://$socket"
  export DOCKER_HOST="$CONTAINER_HOST"
  # Ryuk is an image the sandbox cannot pull, and the sandbox has no /etc/hosts
  # to resolve localhost with.
  export TESTCONTAINERS_RYUK_DISABLED=true
  export TESTCONTAINERS_HOST_OVERRIDE=127.0.0.1
}

stopPodmanSandbox() {
  if [ -z "${podmanSandboxPid:-}" ]; then
    return 0
  fi

  podman --remote rm --all --force > /dev/null 2>&1 || true
  kill "$podmanSandboxPid" || true
  wait "$podmanSandboxPid" || true
}
