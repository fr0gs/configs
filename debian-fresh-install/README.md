# Debian Fresh Installation Task List

This documents serves as a series of guidelines that remind me what to do and what
to avoid when I do a fresh install of a Debian/Ubuntu like distribution.


## 1. ATI drivers

The **fglrx-driver** is not compatible with my ATI card:

```bash
lspci | grep VGA
```

spits this

```
01:00.0 VGA compatible controller: Advanced Micro Devices, Inc. [AMD/ATI] Madison [Mobility Radeon HD 5650/5750 / 6530M/6550M]
```

I need to install the free **radeon** controller. For Debian 8 "Jessie":

1. Add contrib and non-freee components to /etc/apt/sources.list

```
deb http://http.debian.net/debian/ jessie main contrib non-free
```

Then update:

```
sudo apt-get update
```

2. Install packages

```
sudo apt-get install firmware-linux-nonfree libgl1-mesa-dri xserver-xorg-video-ati
```

This will permit to enable dual-screen mode.


## 2. Google Chrome

1. Previously install needed packages:

```
sudo apt-get install libappindicator1 libcurl3
sudo apt-get install -f
```

2. Download [Google Chrome](https://www.google.es/chrome/browser/desktop/index.html) and install it.

## 3. Github Atom Editor
## 4. TexMaker & texlive-extra

```
sudo apt-get install texmaker
```

## 5. Dropbox
## 6. Skype

Steps directly copypasted from Debian Wiki.

```
sudo dpkg --add-architecture i386
sudo aptitude update
sudo aptitude install libc6:i386 libqt4-dbus:i386 libqt4-network:i386 libqt4-xml:i386 libqtcore4:i386 libqtgui4:i386 libqtwebkit4:i386 libstdc++6:i386 libx11-6:i386 libxext6:i386 libxss1:i386 libxv1:i386 libssl1.0.0:i386 libpulse0:i386 libasound2-plugins:i386
wget -O skype-install.deb http://www.skype.com/go/getskype-linux-deb
sudo dpkg -i skype-install.deb
```

## 7. Cpulimit

Install scripts in my repo: [https://github.com/fr0gs/configs/tree/master/debian-fresh-install/cpulimit-own](https://github.com/fr0gs/configs/tree/master/debian-fresh-install/cpulimit-own)



## Credits
- Credits to https://gist.github.com/zenorocha for the Markdown template.
