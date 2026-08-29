#!/bin/bash
# Incremental rebuild: compile changed sources, then link manually without LTO
set -e
cd "$(dirname "$0")"

docker run --rm -t -u $(id -u) \
  -v "$PWD:/usr/src/tdesktop" \
  --memory=12g --memory-swap=20g \
  -w /usr/src/tdesktop/out \
  tdesktop:centos_env \
  bash -lc 'ninja -f build-Release.ninja -j6 td_mtproto td_ui td_lang lib_base lib_ui || true'

docker run --rm -t -u $(id -u) \
  -v "$PWD:/usr/src/tdesktop" \
  --memory=12g --memory-swap=20g \
  -w /usr/src/tdesktop/out \
  tdesktop:centos_env \
  bash -lc '/opt/rh/gcc-toolset-15/root/usr/bin/c++ -O3 -fno-lto -pipe -fPIC \
    -fno-strict-aliasing -fexceptions -fasynchronous-unwind-tables \
    -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -O3 -DNDEBUG \
    -static-libstdc++ -static-libgcc -static-libasan -pthread \
    -Wl,--push-state,--no-as-needed,-ldl,--pop-state -Wl,--as-needed -Wl,-z,muldefs \
    -Wno-odr -Wno-inline -pthread -Wl,--as-needed -Wl,--gc-sections \
    -Wl,--strip-debug \
    @CMakeFiles/Telegram.Release.rsp -o Release/Telegram'

echo "Done: out/Release/Telegram"
