SUMMARY = "Run the Exein Pulsar agent as a systemd service"
DESCRIPTION = "A systemd unit for pulsard. meta-exein installs the Pulsar binaries and \
no unit, so on a systemd image the agent is present and never runs, which is easy to \
miss because nothing fails."
HOMEPAGE = "https://github.com/technosec-dev/rpi5-hailo8-toolkit"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://pulsar.service \
    file://pulsar-check-modules \
"

inherit allarch systemd

# Only local files, so there is no unpacked source tree to point S at.
S = "${UNPACKDIR}"

SYSTEMD_SERVICE:${PN} = "pulsar.service"
RDEPENDS:${PN} = "pulsar"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/pulsar.service ${D}${systemd_system_unitdir}/
    sed -i -e 's,@LIBEXECDIR@,${libexecdir},g' ${D}${systemd_system_unitdir}/pulsar.service

    # Fails the start when process-monitor did not come up; see the script.
    install -d ${D}${libexecdir}/${BPN}
    install -m 0755 ${UNPACKDIR}/pulsar-check-modules ${D}${libexecdir}/${BPN}/
}

FILES:${PN} = "${systemd_system_unitdir} ${libexecdir}/${BPN}"
