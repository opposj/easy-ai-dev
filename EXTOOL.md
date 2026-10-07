### cuda

- Versioned with `cuda@<major>.<minor>.<patch>`, determined by `nvidia-smi` and `pacman -Ss '^cuda$'`
- To integrate GPU, use `docker run --gpus all`
- Use package: `pkgconf --list-all && pkgconf --cflags --libs <package>`
