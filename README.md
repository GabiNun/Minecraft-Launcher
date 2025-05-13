# 🌳 Minecraft Launcher

A lightweight Minecraft launcher built in C++.

---

## 🔧 How to Compile

### 1. Install Dependencies

Install **MinGW** and the required tools:

```bash
pacman -S mingw-w64-x86_64-gcc
pacman -Syu mingw-w64-x86_64-curl
```

---

### 2. Prepare Your Project

- Download [`Launcher.cpp`](https://github.com/GabiNun/Minecraft-Launcher/blob/main/Launcher.cpp) and place it into your project folder.
- Download the required files and folders from this ZIP archive:  
  [Files and folders ZIP](https://github.com/GabiNun/Minecraft-Launcher/raw/refs/heads/main/Dependencies.zip)
- Extract everything into the **same directory** as `Launcher.cpp`.

---

### 3. Compile the Launcher

`cd into your project's directory`

Run the following command in your terminal:

```bash
g++ Launcher.cpp miniz.c miniz_tdef.c miniz_tinfl.c miniz_zip.c -o Launcher.exe \
-std=c++17 -static -static-libgcc -static-libstdc++ -s -Os \
-lcurl -lnghttp3 -lnghttp2 -lidn2 -lpsl -lunistring -liconv \
-lssh2 -lssl -lcrypto -lzstd -lbrotlidec -lbrotlicommon -lz \
-lws2_32 -lwldap32 -lcrypt32 -lbcrypt -mwindows
```

After successful compilation, you'll find `Launcher.exe` in your project folder.

---

## 🚀 Or Download Precompiled Version

You can download the latest precompiled `.exe` here:  
➡️ [Releases Page](https://github.com/GabiNun/Minecraft-Launcher/releases/latest)

---

## 📦 Requirements to Run

- ✅ **Java 25** or lower installed on your system  
- ✅ `cacert.pem` file (needed for login, but **not** required to play)
- 💡 **Tip:** You may delete all files **except** `cacert.pem` And `Launcher.exe`.

---
