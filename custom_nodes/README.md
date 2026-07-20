# custom_nodes/

Cloned at install time (gitignored). On first useful run:

```bash
./scripts/install-custom-nodes.sh
# or
INSTALL_CUSTOM_NODES=1 docker compose up -d --build
```

ComfyUI-Manager is auto-seeded by the container entrypoint if missing.
