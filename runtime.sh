#!/bin/bash

set -ex

SCRIPT_PATH="$(dirname "$(realpath "$0")")"
SYS_RULE="${SYS_RULE:-$1}"
BUILD_RUNTIME="${BUILD_RUNTIME:-$2}"
BUILD_RUNTIME="${BUILD_RUNTIME:-/tmp}"

build_dir="${BUILD_RUNTIME}/build"

distros=('debian' 'alpine' 'vanilla')
package_version="${3:-1}"

build() {
    cp -r rootfs /tmp/rootfs
    cd /tmp/rootfs
    case $DEBIAN_SYS in
        1)
            rm -rf etc/init.d
            tar -czvf /dist/raw.tar.gz *
            ;;
        *)
            rm -rf etc/systemd
            tar -czvf /dist/raw-alpine.tar.gz *
            ;;
    esac
    cd -
    rm -rf /tmp/rootfs
    chown -R 0:0 /dist
}

package() {
    distro="$1"

    case "$distro" in
        alpine)
                rm -rf /dist/alpine
                rm -rf "${build_dir}"
                mkdir -p "${build_dir}"
                cp -r "$SCRIPT_PATH/packaging/alpine" "${build_dir}/"
                package_dir="${build_dir}/alpine/pkg"
                mkdir -p "${package_dir}"
                cp /dist/raw-alpine.tar.gz "${package_dir}/raw.tar.gz"
                cp "${build_dir}/alpine/APKBUILD.template" "${package_dir}/APKBUILD"
                sed -i "s/PACKVER/$(echo "${package_version}" | sed -e 's/nightly/0/g')/g" "${package_dir}/APKBUILD"
                output_dir="${build_dir}"
                BUILDUSER="abuilder"
                adduser "$BUILDUSER" -D || true
                usermod -aG abuild "$BUILDUSER" || true
                mkdir -p "/home/$BUILDUSER/.abuild"
                chown -R "$BUILDUSER:$BUILDUSER" "/home/$BUILDUSER"
                if [ -d "/dist/alpine-keys" ]; then
                    cp -r "/dist/alpine-keys" "/home/$BUILDUSER/.abuild"
                else
                    su "$BUILDUSER" -c "abuild-keygen -an"
                fi
                chown -R "$BUILDUSER:$BUILDUSER" "/home/$BUILDUSER/.abuild"
                chown -R "$BUILDUSER:$BUILDUSER" "${build_dir}"
                akeys="$(find "/home/$BUILDUSER/.abuild/" -type f -name '*.rsa.pub' | tr '\n' ' ')"
                for export_key in $akeys; do
                    cp -v "$export_key" /etc/apk/keys/
                done
                mkdir -p /root/.abuild/
                for export_key in $akeys; do
                    cp -v "$export_key" /root/.abuild/
                done
                chown -R 0:0 /root
                # Checksum
                su "$BUILDUSER" -c "cd ${package_dir}
                abuild checksum"
                # Build
                apk add $(grep "depends\=" "${package_dir}/APKBUILD" | cut -f 2 -d '"' | tr '\n' ' ') \
                        $(grep "makedepends\=" "${package_dir}/APKBUILD" | cut -f  2 -d '"' | tr '\n' ' ')
                su "$BUILDUSER" -c "cd ${package_dir}
                abuild -rKFc"
                mkdir -p /dist/alpine/keys
                cp -rv "/home/$BUILDUSER/packages/alpine/x86_64" /dist/alpine/pkg
                for export_key in $akeys; do
                    cp -v "$export_key" /dist/alpine/keys/
                done
                chown -R 0:0 /dist
                ;;
        debian)
                rm -rf /dist/debian
                rm -rf "${build_dir}"
                mkdir -p "${build_dir}"
                cp -r "$SCRIPT_PATH/packaging/debian" "${build_dir}/"
                package_dir="${build_dir}/debian"
                mkdir -p "${build_dir}/debian/bin/DEBIAN"
                cp /dist/raw.tar.gz "${build_dir}/debian/bin/raw.tar.gz"
                cp "${package_dir}/control.main" "${build_dir}/debian/bin/DEBIAN/control"
                cp "${package_dir}/postinst" "${build_dir}/debian/bin/DEBIAN/postinst"
                cp "${package_dir}/postrm" "${build_dir}/debian/bin/DEBIAN/postrm"
                cd ${build_dir}/debian/bin
                tar -xvf raw.tar.gz
                rm -f raw.tar.gz
                cd -
                chmod 0755 "${build_dir}"/debian/bin/*
                chmod 0755 "${build_dir}"/debian/bin/DEBIAN/*
                chmod 0644 "${build_dir}"/debian/bin/DEBIAN/control
                find "${build_dir}"/debian/bin/* -type d | xargs -I '{}' chmod 0755 "{}"
                find "${build_dir}"/debian/bin/DEBIAN -type f | xargs -I '{}' sed -i "s/PACKVER/${package_version}/g" "{}"
                chown -R 0:0 "${build_dir}"/debian/bin/*
                dpkg-deb --build "${build_dir}"/debian/bin
                mkdir /dist/debian
                mv "${build_dir}/debian/bin.deb" /dist/debian/10moons-driver.deb
                chown -R 0:0 /dist
                ;;
        *)

                ;;
    esac
}

case "$SYS_RULE" in
        vanilla)
                build
                ;;
        alpine|debian)
                package "$SYS_RULE"
                ;;
        *)
                build
                for distro in ${distros[@]}; do
                    package $distro;
                done
                ;;
esac
