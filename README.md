# Raspberry Pi 5 + Hailo-8 toolkit

Build a Yocto image for the Raspberry Pi 5 with the Hailo-8 AI HAT+ (26 TOPS)
on Yocto 6.0 "wrynose", and know what to check when it comes up.

Hailo's own layer, [meta-hailo](https://github.com/hailo-ai/meta-hailo), stops at
scarthgap (Yocto 5.0). Nothing official exists for anything newer. A community
port to whinlatter and wrynose has been waiting as
[pull request #105](https://github.com/hailo-ai/meta-hailo/pull/105) since
January 2026, and it is good: it parses, it builds, and the driver, firmware and
runtime it produces work on the board. It also has a few defects that only show
up in the output, not in the build log. This repository pins that port and
carries a small layer that fixes them, plus the board-level things a
`core-image-minimal` on the Pi 5 leaves out.

## What you end up with

A Pi 5 image of your own with the Hailo-8 PCIe driver, its firmware, HailoRT
4.24.0 with `hailortcli`, the Python bindings, the HailoRT service and the
GStreamer element, all from source and pinned. The Pi 5's fan is under kernel
control and a weak power supply is reported in the kernel log instead of going
unnoticed. The SBOM records the right licence for every Hailo component.

Optionally, the Exein Pulsar runtime security agent, with its eBPF LSM
programs loaded.

## What is here

- `meta-rpi5-hailo`, a Yocto layer that corrects the licences the port records
  in the SBOM and, when `meta-exein` is present, adds what Pulsar needs on this
  board (see "Optional: Exein Pulsar");
- this guide: the layers and revisions, the configuration, and what the board
  tells you when it works and when it does not.

## What you need

- A **Raspberry Pi 5**.
- The **Raspberry Pi AI HAT+ 26T**, which has the Hailo-8 soldered on. The 13T
  model, and the AI Kit, use the Hailo-8L instead. It uses the same driver and
  firmware, but nothing here has been tried on one.
- **The official 27 W USB-C supply** (5.1 V, 5 A), or another 5 V 5 A USB-PD
  supply with a short, thick cable. The Hailo-8 adds several watts under load,
  and on a weaker supply the chip can drop off the PCIe bus in the middle of an
  inference run.
- A microSD card. The image is under 1 GB uncompressed.
- A Linux build host with the
  [packages Yocto requires](https://docs.yoctoproject.org/ref-manual/system-requirements.html),
  plenty of RAM (see "Building") and about 175 GB of free disk. The tree this
  guide was built in used 173 GB (30 GB of downloads, 9.5 GB of sstate, 133 GB
  of `tmp`), and that includes a TAPPAS build on top.

## Where meta-hailo stands

As of November 2026, `hailo-ai/meta-hailo` has no branch, tag or `layer.conf`
newer than scarthgap. The latest Hailo-8 branch is `hailo8-scarthgap` at HailoRT
4.24.0.

Pull request #105, by Zoltán Böszörményi, is branch `hailo8-whinlatter` of
[zboszor/meta-hailo](https://github.com/zboszor/meta-hailo). It moves the layers
to whinlatter and wrynose and drops scarthgap on purpose. The bigger change is
inside HailoRT. Upstream, HailoRT's CMake downloads protobuf, gRPC, spdlog and a
dozen other libraries at build time. The port replaces every one of those with
the recipe Yocto already has, so the build is offline after the fetch and the
SBOM shows what is really in the image.

This guide pins the port at `069d917`. That commit is the head of the branch and
of the pull request, and it is the one that was built and booted.

## The layers

| Layer | Branch | Revision |
|---|---|---|
| [bitbake](https://git.openembedded.org/bitbake) | `2.18` | `6e260eb6ab1631607ea414d9ff8ede1155faa5d9` |
| [openembedded-core](https://git.openembedded.org/openembedded-core) | `wrynose` | `ae5a301091f5b0574ea7444aab40b309b6d9f3f2` |
| [meta-yocto](https://git.yoctoproject.org/meta-yocto) | `wrynose` | `79b6d87030178bed0088ad3b00aa6dfbabac37c4` |
| [meta-openembedded](https://git.openembedded.org/meta-openembedded) | `wrynose` | `c734c2cb9713dbd6d50697a9f6c25ebdf3ae589e` |
| [meta-raspberrypi](https://git.yoctoproject.org/meta-raspberrypi) | `wrynose` | `919588393f41b48cb6c5d832aa35e58a19b6762d` |
| [meta-hailo (PR #105)](https://github.com/zboszor/meta-hailo) | `hailo8-whinlatter` | `069d917d390295388362f4523c95f3ac16e5ed31` |
| [meta-exein](https://github.com/exein-io/meta-exein) (optional) | `wrynose` | `78e8680ad73f731c216d8cd1e5333e8eeebf48c0` |

```
mkdir hailo8-wrynose && cd hailo8-wrynose
mkdir layers && cd layers

git clone -b 2.18 https://git.openembedded.org/bitbake
git clone -b wrynose https://git.openembedded.org/openembedded-core
git clone -b wrynose https://git.yoctoproject.org/meta-yocto
git clone -b wrynose https://git.openembedded.org/meta-openembedded
git clone -b wrynose https://git.yoctoproject.org/meta-raspberrypi
git clone -b hailo8-whinlatter https://github.com/zboszor/meta-hailo
git clone https://github.com/technosec-dev/rpi5-hailo8-toolkit

git -C bitbake            checkout 6e260eb6ab1631607ea414d9ff8ede1155faa5d9
git -C openembedded-core  checkout ae5a301091f5b0574ea7444aab40b309b6d9f3f2
git -C meta-yocto         checkout 79b6d87030178bed0088ad3b00aa6dfbabac37c4
git -C meta-openembedded  checkout c734c2cb9713dbd6d50697a9f6c25ebdf3ae589e
git -C meta-raspberrypi   checkout 919588393f41b48cb6c5d832aa35e58a19b6762d
git -C meta-hailo         checkout 069d917d390295388362f4523c95f3ac16e5ed31
cd ..

export PATH=$PWD/layers/bitbake/bin:$PATH
source layers/openembedded-core/oe-init-build-env build
```

If the contributor's branch moves or disappears, the same commit stays
reachable through the pull request:
`git fetch https://github.com/hailo-ai/meta-hailo pull/105/head`.

Then `conf/bblayers.conf`. `meta-hailo` holds three layers and
`meta-rpi5-hailo` sits in a subdirectory of this repository, so point at the
subdirectories and not the repository roots:

```
BBLAYERS = " \
    /path/to/layers/openembedded-core/meta \
    /path/to/layers/meta-yocto/meta-poky \
    /path/to/layers/meta-openembedded/meta-oe \
    /path/to/layers/meta-openembedded/meta-python \
    /path/to/layers/meta-raspberrypi \
    /path/to/layers/meta-hailo/meta-hailo-accelerator \
    /path/to/layers/meta-hailo/meta-hailo-libhailort \
    /path/to/layers/rpi5-hailo8-toolkit/meta-rpi5-hailo \
"
```

`meta-oe` and `meta-python` are required, although meta-hailo only declares
`core`. HailoRT is built against gRPC, protobuf, abseil, spdlog, CLI11,
nlohmann-json, Eigen, c-ares and re2 from `meta-oe`, and the Python bindings
need pybind11, netifaces and future from `meta-python`. Leave either out and the
parse fails on a missing dependency, not on a missing layer.

`meta-hailo-tappas` is left out on purpose; see "TAPPAS". `meta-exein` is
optional; see "Optional: Exein Pulsar".

## The configuration

Add to `conf/local.conf`:

```
MACHINE = "raspberrypi5"
DISTRO = "poky"

# hailort-service ships only a systemd unit, and poky defaults to sysvinit.
# On sysvinit the service installs and never starts, with nothing to say why.
INIT_MANAGER = "systemd"

# Builds the HailoRT service, which lets several processes share one Hailo-8.
# It is what pulls gRPC into HailoRT. meta-hailo defaults to "0"; this guide's
# image was built and tested with "1".
HAILO_BUILD_SERVICE = "1"

CORE_IMAGE_EXTRA_INSTALL += " \
    hailo-pci hailo-firmware \
    libhailort hailortcli hailort-service pyhailort libgsthailo \
"

# core-image-minimal installs only the machine's essential recommends, and on
# the Pi that leaves out every loadable kernel module. Two of them matter here:
# without pwm-fan nothing controls the Pi 5 fan, so it runs at full speed from
# power-on; without raspberrypi-hwmon an undervolting supply is never reported.
CORE_IMAGE_EXTRA_INSTALL += "kernel-module-pwm-fan kernel-module-raspberrypi-hwmon"
```

No modprobe options for the driver, and no PCIe settings in `config.txt`. Both
are explained under "Worth knowing".

## Building

```
bitbake core-image-minimal
```

Most of the build is the usual toolchain and kernel. The Hailo-specific weight
is gRPC and its dependencies, and HailoRT itself.

Memory is the limit, more than CPU. Poky enables `ptest` by default, so the
test suites of HailoRT's header-only dependencies are compiled too, and those
are the peak: nlohmann-json's suite alone runs eight compilers of 0.5 to 1 GB
each. On a 16-core host with 32 GB of RAM, the default parallelism (16 tasks,
each `make -j 16`) drove the machine into swap. When the swap sits on the same
disk as the build, the bitbake server then misses its 60-second keep-alive and
the build stops with:

```
Timeout while waiting for a reply from the bitbake server (60s ...)
```

These limits avoided it on that host:

```
BB_NUMBER_THREADS = "8"
PARALLEL_MAKE = "-j 15 -l 20"
```

`-l` bounds the load average, not memory, so if you are still swapping, lower
`BB_NUMBER_THREADS` first.

If a build is ever killed, by you or by the timeout above, clean the recipes
that were running at that moment before you start again:

```
bitbake -c clean <recipe> ...
```

A killed compiler leaves truncated object files with new timestamps, `make`
treats them as up to date, and the next attempt fails at link time with
hundreds of undefined symbols in a recipe that has nothing wrong with it. Stop a
build with a single Ctrl-C and let it finish the running tasks instead.

## Flashing

The image is
`tmp/deploy/images/raspberrypi5/core-image-minimal-raspberrypi5.rootfs.wic.bz2`,
with a `.wic.bmap` next to it. Check which device is the card with `lsblk`
first; both commands below overwrite whatever they are pointed at.

```
sudo bmaptool copy core-image-minimal-raspberrypi5.rootfs.wic.bz2 /dev/sdX
```

or, without bmaptool:

```
bzcat core-image-minimal-raspberrypi5.rootfs.wic.bz2 | sudo dd of=/dev/sdX bs=4M conv=fsync status=progress
```

For a first test you will want a way in. These lines give a root login with no
password over SSH and on the serial header. Do not ship them.

```
EXTRA_IMAGE_FEATURES += "ssh-server-dropbear allow-empty-password empty-root-password allow-root-login"
ENABLE_UART = "1"
```

## First boot: what to check

The output below is from the board this guide was written on.

The HAT is on the PCIe bus:

```
# lspci -nn
0001:01:00.0 Co-processor [0b40]: Hailo Technologies Ltd. Hailo-8 AI Processor [1e60:2864] (rev 01)
```

`lspci` is in `pciutils`, which the configuration above does not install; add it
for the first boot. The PCI ID is the same for the Hailo-8 and the Hailo-8L, so
it does not tell you which one you have.

The driver probed it and loaded the firmware:

```
# dmesg | grep hailo
hailo: Init module. driver version 4.24.0
hailo 0001:01:00.0: Probing: Setting max_desc_page_size to 4096, (page_size=16384)
hailo 0001:01:00.0: Writing file hailo/hailo8_fw.bin
hailo 0001:01:00.0: File hailo/hailo8_fw.bin written successfully
hailo 0001:01:00.0: NNC Firmware loaded successfully
hailo 0001:01:00.0: Probing: Added board 1e60-2864, /dev/hailo0
```

The driver also reports writing `hailo8_board_cfg.bin` and `hailo8_fw_cfg.bin`.
Those files are optional, the image does not have them, and the driver says
"written successfully" anyway. Nothing is wrong.

The chip answers, and this is where you learn which one you have:

```
# hailortcli fw-control identify
Firmware Version: 4.24.0 (release,app,extended context switch buffer)
Device Architecture: HAILO8
```

`HAILO8L` there means a Hailo-8L. The firmware version should match the driver
and HailoRT (4.24.0).

The service is running, and the supply is good enough:

```
# systemctl is-active hailort.service
active
# dmesg | grep -i voltage
```

The second command must print nothing. Driver probe, firmware load and
`identify` are light work and all pass on a supply that cannot carry inference,
so an `Undervoltage detected!` line here means: change the supply or the cable
before you run a model.

## Running a model

The Hailo-8 runs compiled models (HEF files). They are specific to the chip and
to the HailoRT release, and the
[Hailo Model Zoo](https://github.com/hailo-ai/hailo_model_zoo) publishes them
precompiled. Two things to get right:

- **The Model Zoo release.** Its `master` branch is the 5.x line for the
  Hailo-10H and Hailo-15. Hailo-8 is on HailoRT 4.x and Model Zoo 2.x, and
  HailoRT 4.24.0 pairs with Model Zoo **v2.20.0**.
- **The chip.** Take the `hailo8` directory for the 26T, `hailo8l` for the 13T
  and the AI Kit.

```
wget https://hailo-model-zoo.s3.eu-west-2.amazonaws.com/ModelZoo/Compiled/v2.20.0/hailo8/yolov8s.hef
hailortcli parse-hef yolov8s.hef      # "Architecture HEF was compiled for: HAILO8"
hailortcli run yolov8s.hef
```

With no `--input-files`, `hailortcli run` streams random data through the model
and reports the frames per second; `-t` sets how many seconds it runs. On this
image:

```
# hailortcli run -t 20 yolov8s.hef
> Inference result:
 Network group: yolov8s
    Frames count: 9830
    FPS: 491.31
    Send Rate: 4829.74 Mbit/s
    Recv Rate: 4799.56 Mbit/s
```

That is the figure Hailo publishes for this model on the Hailo-8, 491 FPS,
which the Model Zoo measured on an x86 host with a PCIe Gen 3 x4 link. The Pi
5's single Gen 3 lane does not hold this model back.

During the run the SoC warmed from 45 to 52 °C and the fan came on by itself
once it passed 50 °C. That is `pwm-fan` doing its job; without it the fan
would have been at full speed the whole time.

## Optional: Exein Pulsar

[Pulsar](https://github.com/exein-io/pulsar) is Exein's runtime security agent:
eBPF programs in the kernel report process, file and network activity, and a
rules engine flags what looks wrong. It comes from
[meta-exein](https://github.com/exein-io/meta-exein), whose `wrynose` branch
carries Pulsar 0.10.1.

```
git -C layers clone -b wrynose https://github.com/exein-io/meta-exein
git -C layers/meta-exein checkout 78e8680ad73f731c216d8cd1e5333e8eeebf48c0
```

Add `/path/to/layers/meta-exein` to `BBLAYERS` (it needs `meta-oe`, which is
already there), and to `conf/local.conf`:

```
# Builds the kernel with BTF, which Pulsar's eBPF programs need at run time.
DISTRO_FEATURES:append = " btf"
CORE_IMAGE_EXTRA_INSTALL += "pulsar rpi5-pulsar-service"
```

A new distro feature changes the signature of much of the tree, so expect a
large part of the build to run again.

Once `meta-exein` is in `bblayers.conf`, and only then, `meta-rpi5-hailo` adds:

- **`rpi5-pulsar-service`**, a systemd unit for `pulsard`, which meta-exein
  does not ship.
- **`CONFIG_LSM="bpf"`**, so the kernel starts the BPF LSM that meta-exein's
  fragment builds in. It adds `bpf` and nothing else; to run AppArmor as well,
  set `CONFIG_LSM="apparmor,bpf"` in a fragment of your own.
- **A check at the kernel's `do_configure`** that prints a
  `meta-rpi5-hailo: Pulsar needs ...` warning for each symbol in
  `RPI5_PULSAR_EXPECTED_CONFIG` that did not reach the kernel configuration.
- **A start check** that restarts `pulsard` when its process-monitor did not
  start ([exein-io/pulsar#377](https://github.com/exein-io/pulsar/issues/377)).

### What to check on the board

```
# cat /sys/kernel/security/lsm
capability,bpf
# journalctl -u pulsar -b | grep "LSM not supported"
# pulsar status
| file-system-monitor | Running                                  |
| network-monitor     | Running                                  |
| process-monitor     | Running                                  |
| rules-engine        | Running                                  |
| threat-logger       | Running(["Failed to connect to syslog"]) |
```

`bpf` must be in the first list, the `journalctl` line must print nothing, and
every monitor must be `Running` (`desktop-notifier` and `smtp-notifier` stay
`Created`; they are disabled). The syslog warning is harmless: under systemd,
Pulsar sees that its output already goes to the journal and skips syslog on
purpose, then reports that it could not connect to it. Threats still reach the
journal.

To see the LSM path in use rather than merely available, count the BPF LSM
programs (type 29) that the running agent holds:

```
# cat /proc/$(systemctl show -p MainPID --value pulsar)/fdinfo/* | grep -c "^prog_type:.29$"
14
```

On this board it holds 14.

Then `journalctl -u pulsar -f` and log in over SSH from another machine. Every
login shows up as dropbear reading the password file:

```
THREAT /usr/sbin/dropbear (699)] [rules-engine - Open sensitive file] File Opened { filename: /etc/shadow, flags:(O_RDONLY) }
```

The stock rules are generic and expect you to tune them. One more you will see
on this image is `/usr/bin/pulsar` reading its own `/proc/<pid>/maps`, reported
as `Suspicious command targeting /proc filesystem` each time anything runs the
`pulsar` command, the start check included.

Pulsar does not slow the Hailo-8 down: `yolov8s` runs at the same frame rate,
around 460 FPS, with the agent running or stopped.

## Worth knowing

### `force_desc_page_size` is no longer needed, and can hurt

The Pi 5 kernel uses 16 KB pages. Up to HailoRT 4.23.0 the driver sized its DMA
descriptors from the page size, up to 32 KB, and the firmware cannot work with
more than 4 KB. That is why Raspberry Pi OS and older guides ship
`/etc/modprobe.d/hailo_pci.conf` with `options hailo_pci force_desc_page_size=4096`.

Driver 4.24.0 caps it at 4096 itself, which is the
`Setting max_desc_page_size to 4096, (page_size=16384)` line in the boot log,
with no option set. Leave the option out. When the PCIe link's maximum read
request is under 512 bytes, the driver deliberately uses 128- or 256-byte
descriptors to avoid a hardware bug, and forcing 4096 overrides that.

### TAPPAS

`meta-hailo-tappas` builds, but adding it to `bblayers.conf` changes every
image, not only the ones that ask for it. Its `layer.conf` appends
`packagegroup-hailo-tappas-dev-pkg` to `CORE_IMAGE_EXTRA_INSTALL`, which pulls
in all of OpenCV 4.13 and the TAPPAS development files. On this image that is
115 extra packages and 37 MB more, compressed. Reading the layer,
`HAILO_TARGET = "core-image-hailo"` swaps the development group for the runtime
one, but some TAPPAS group is still added to every image.

### PCIe Gen 3 is set for you

The Pi 5's device tree caps the external PCIe port at Gen 2, and many guides
tell you to add `dtparam=pciex1_gen=3` to `config.txt`. For the AI HAT+ you do
not need to:
[Raspberry Pi's documentation](https://www.raspberrypi.com/documentation/computers/ai.html)
says the setting is applied automatically, and on this image, with nothing in
`config.txt` and the device tree still saying Gen 2, the link comes up at
8 GT/s:

```
# dmesg | grep "link up"
brcm-pcie 1000110000.pcie: link up, 8.0 GT/s PCIe x1 (!SSC)
```

The AI Kit is different: the same page says to enable Gen 3 by hand there.

## Troubleshooting

**The fan runs at full speed from power-on.**
`pwm-fan` is not in the image. Check with `lsmod | grep pwm_fan`, and see "The
configuration".

**`lspci` shows no Hailo device.**
Check that the HAT is seated on the PCIe FFC cable at both ends, with the
contacts facing the right way, and that the 40-pin header is connected.

**`hailortcli` says the HEF is not compatible with the device.**
The HEF was compiled for the other chip (`HAILO8` versus `HAILO8L`) or for a
different HailoRT release. Check with `hailortcli parse-hef`, and see "Running a
model".

**The chip disappears in the middle of an inference run.**
Almost always the supply. The kernel log shows `Channel ... hw state out of
sync. num available is 65535` (`0xffff`, what a register read returns once the
device is gone), and `dmesg | grep -i voltage` shows why. Use the official 27 W
supply.

**The board stops responding after the chip has dropped off the bus.**
Reboot it. Do not try to inspect the dead device first: reading its PCIe
configuration space (`lspci -vv`, or `/sys/bus/pci/devices/.../config`) can
block, and the shell that did it with it.

**The build stops with "Timeout while waiting for a reply from the bitbake
server".**
See "Building".

**Pulsar is installed but not running.**
`rpi5-pulsar-service` is not in the image. See "Optional: Exein Pulsar".

## Built by [TechnoSec](https://technosec.net)

Open source, usable with plain Yocto. Issues and pull requests welcome. The
licence fixes here belong in meta-hailo, and they will be offered to pull
request #105; the Pulsar unit belongs in meta-exein, and the start check goes once
exein-io/pulsar#377 is fixed. See also
[arduino-uno-q-toolkit](https://github.com/technosec-dev/arduino-uno-q-toolkit)
and [meta-container-deploy](https://github.com/technosec-dev/meta-container-deploy).

Doing this by hand teaches you the board. Try
[EmbedForge](https://embedforge.io), the enterprise-grade build platform for
device makers: connect its MCP to the AI agent you already use, describe the
device, and it starts the builds, on our cloud or your own runners, with an SBOM
and a declaration of conformity per device for the EU Cyber Resilience Act.

In public preview, access by invitation, so ask if you are building a product on
this.
