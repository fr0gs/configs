# ${1:Debian fresh installation task list}

This documents serves as a series of guidelines that remind me what to do and what
to avoid when I do a fresh install of a Debian/Ubuntu like distribution.


## Install ATI drivers

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


## Install Google Chrome

1. Previously install needed packages:

```
sudo apt-get install libappindicator1 libcurl3
sudo apt-get install -f
```

2. Download [Google Chrome](https://www.google.es/chrome/browser/desktop/index.html) and install it.



## Credits
- Credits to https://gist.github.com/zenorocha for the Markdown template.

