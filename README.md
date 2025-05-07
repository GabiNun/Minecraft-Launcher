# Minecraft-Launcher


complie command

g++ Launcher.cpp miniz.c -o Launcher.exe -std=c++17 -static -static-libgcc -static-libstdc++ -s -Os -lcurl -lnghttp3 -lnghttp2 -lidn2 -lpsl -lunistring -liconv -lssh2 -lssl -lcrypto -lzstd -lbrotlidec -lbrotlicommon -lz -lws2_32 -lwldap32 -lcrypt32 -lbcrypt -mwindows
