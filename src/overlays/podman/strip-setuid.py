import hashlib
import io
import json
import os
import sys
import tarfile

SETUID_AND_SETGID = 0o6000


class HashingWriter:
    def __init__(self, target):
        self.target = target
        self.digest = hashlib.sha256()
        self.offset = 0

    def write(self, data):
        self.digest.update(data)
        self.offset += len(data)
        return self.target.write(data)

    def tell(self):
        return self.offset


def strip_layer(layer, path):
    with open(path, "wb") as target:
        writer = HashingWriter(target)
        with tarfile.open(fileobj=layer, mode="r:*") as source:
            with tarfile.open(
                fileobj=writer, mode="w", format=tarfile.PAX_FORMAT
            ) as stripped:
                for member in source:
                    member.mode &= ~SETUID_AND_SETGID
                    content = source.extractfile(member) if member.isreg() else None
                    stripped.addfile(member, content)
    return writer.digest.hexdigest()


def add_bytes(archive, name, content):
    info = tarfile.TarInfo(name)
    info.size = len(content)
    info.mode = 0o644
    archive.addfile(info, io.BytesIO(content))


def main(source_path, target_path):
    with tarfile.open(source_path) as source:
        manifest = json.load(source.extractfile("manifest.json"))
        replaced = {"manifest.json"}
        layers = {}
        configs = {}

        for image in manifest:
            replaced.add(image["Config"])
            config = json.load(source.extractfile(image["Config"]))
            digests = []
            for name in image["Layers"]:
                replaced.add(name)
                if name not in layers:
                    path = f"layer-{len(layers)}.tar"
                    layers[name] = (path, strip_layer(source.extractfile(name), path))
                digests.append(layers[name][1])

            config["rootfs"]["diff_ids"] = [f"sha256:{digest}" for digest in digests]
            config_bytes = json.dumps(config, separators=(",", ":")).encode()
            config_name = f"{hashlib.sha256(config_bytes).hexdigest()}.json"
            configs[config_name] = config_bytes
            image["Config"] = config_name
            image["Layers"] = [f"{digest}.tar" for digest in digests]

        with tarfile.open(target_path, "w") as target:
            for path, digest in layers.values():
                info = tarfile.TarInfo(f"{digest}.tar")
                info.size = os.path.getsize(path)
                info.mode = 0o644
                with open(path, "rb") as layer:
                    target.addfile(info, layer)
            for name, content in configs.items():
                add_bytes(target, name, content)
            add_bytes(target, "manifest.json", json.dumps(manifest).encode())
            for member in source:
                if member.name not in replaced:
                    content = source.extractfile(member) if member.isreg() else None
                    target.addfile(member, content)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
