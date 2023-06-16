---
description: This page will cover how to install Cosmo make your first program!
---

# ⭐ Getting Started

## Installation

### Cosmo Installer

If you want a quick cross-platform setup, then the installer is for you. You can find the latest release for the Cosmo installer [here](https://github.com/cosmo-lang/cosmo-installer/releases).

{% hint style="info" %}
If you experience any problems or bugs, please [create an issue](https://github.com/cosmo-lang/cosmo-installer/issues).
{% endhint %}

### From source

If you want to customize your installation, build your own fork of Cosmo, the installer isn't supported on your device, or you just don't want to use the installer, then this is for you.

1. Download the [source code](https://github.com/cosmo-lang/cosmo).
2. Install [Crystal](https://crystal-lang.org/install/).
3. If on OSX/Linux, run `sudo make install` . That's it. On Windows, just run `shards build --release` and add the `bin` folder to your PATH.

## Writing a "Hello, world" program

To get started writing your first Cosmo app, first create a new folder.

<figure><img src="../.gitbook/assets/image (3).png" alt=""><figcaption><p>I named mine <code>test</code>.</p></figcaption></figure>

Now, create your Cosmo file. Cosmo sees files named `main` or the name of your project as an entry point. I will use the name of my project in this case, `test`, to give an example.

<figure><img src="../.gitbook/assets/image (4).png" alt=""><figcaption></figcaption></figure>

A main function is optional in Cosmo, except for if you want to accept the arguments the program was executed with. The `args` parameter is also optional. Be sure to mark your main function as `public` and return an `int`, which will be the exit code of the program.

<figure><img src="../.gitbook/assets/image (6).png" alt=""><figcaption><p>What a full main function should look like.</p></figcaption></figure>

<figure><img src="../.gitbook/assets/image (1).png" alt=""><figcaption><p>The output of this script.</p></figcaption></figure>
