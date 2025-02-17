# ai-photomaker2


```bash
docker build -t olilanz/ai-photomaker2 .
```

```bash
docker run -it --rm --name ai-photomaker2 \
  --shm-size 24g --gpus '"device=1"' \
  -p 7861:7860 \
  -v /mnt/cache/appdata/ai-photomaker2:/workspace \
  -e PM2_AUTO_UPDATE=1 \
  olilanz/ai-photomaker2
```
