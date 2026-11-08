# Pulsar on the Raspberry Pi kernel. Applied only with the "btf" distro
# feature, the same switch meta-exein uses for its own kernel fragment.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "${@bb.utils.contains('DISTRO_FEATURES', 'btf', 'file://rpi5-exein.cfg', '', d)}"

# What Pulsar needs, checked against the configuration Kconfig produced, with a
# warning at do_configure for each symbol that did not make it.
RPI5_PULSAR_EXPECTED_CONFIG ?= " \
    CONFIG_BPF_LSM=y CONFIG_SECURITY_NETWORK=y CONFIG_SECURITY_PATH=y \
    CONFIG_DEBUG_INFO_BTF=y CONFIG_FTRACE_SYSCALLS=y CONFIG_LSM="bpf" \
"

python rpi5_pulsar_check_kernel_config() {
    import os, shlex

    if not bb.utils.contains('DISTRO_FEATURES', 'btf', True, False, d):
        return

    config = os.path.join(d.getVar('B'), '.config')
    if not os.path.exists(config):
        return

    actual = {}
    with open(config) as handle:
        for line in handle:
            line = line.strip()
            if line.startswith('CONFIG_') and '=' in line:
                key, _, value = line.partition('=')
                actual[key] = value
            elif line.startswith('# CONFIG_') and line.endswith(' is not set'):
                actual[line[2:-len(' is not set')]] = 'n'

    for item in shlex.split(d.getVar('RPI5_PULSAR_EXPECTED_CONFIG') or '', posix=False):
        key, _, want = item.partition('=')
        got = actual.get(key, 'n')
        if got != want:
            bb.warn("meta-rpi5-hailo: Pulsar needs %s=%s, but the kernel was "
                    "configured with %s=%s. Pulsar will still start, and fall "
                    "back to kprobes with only a warning in its own log."
                    % (key, want, key, got))
}
do_configure[postfuncs] += "rpi5_pulsar_check_kernel_config"
