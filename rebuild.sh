#!/bin/bash
# Incremental rebuild: compile changed sources, then link manually without LTO
set -e
cd "$(dirname "$0")"

# Compile everything the binary depends on; a real compile error stops the script here
docker run --rm -t -u $(id -u) \
  -v "$PWD:/usr/src/tdesktop" \
  --memory=12g --memory-swap=20g \
  -w /usr/src/tdesktop/out \
  tdesktop:centos_env \
  bash -lc 'ninja -f build-Release.ninja -j3 $(ninja -f build-Release.ninja -t inputs Release/Lotusgram | grep "\.o$" | tr "\n" " ")'

# Link manually: the LTO link ninja would run does not fit in RAM
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
    @CMakeFiles/Telegram.Release.rsp -o Release/Lotusgram'

echo "Done: out/Release/Lotusgram"
