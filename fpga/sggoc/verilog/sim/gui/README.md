# Build

```
brew install --HEAD verilator # need >= v4.210
git submodule update --init
mkdir build
cd build
cmake ..
make -j$(nproc)
./sggoc romfile.gg
```
