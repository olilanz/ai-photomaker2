# ai-photomaker2


```bash
docker build -t olilanz/ai-photomaker2 .
```

```bash
docker run -it --rm --name ai-photomaker2 \
  --shm-size 24g --gpus all \
  -p 7860:7860 \
  -v /mnt/cache/appdata/ai-photomaker2:/workspace \
  -e YUEGP_AUTO_UPDATE=1 \
  --network host \
  olilanz/ai-photomaker2
```
