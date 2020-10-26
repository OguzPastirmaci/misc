FROM fedora:rawhide

RUN dnf install -y golang redhat-rpm-config git pcre-devel glibc-static which rpm-build rpmdevtools hostname procps-ng

RUN go get github.com/tools/godep

ARG go_version
ARG go_macros_version

# Bootstrap a golang RPM build from Fedora Rawhide, but disable tests because they require privileged mode
RUN rpm -Uvh --force http://mirrors.kernel.org/fedora/development/rawhide/Everything/x86_64/os/Packages/g/go-srpm-macros-${go_macros_version}.noarch.rpm \
	&& ln -s /usr/lib/rpm/macros.d/macros.go-srpm /etc/rpm/ \
	&& rpmbuild --define '%check exit 0' --rebuild http://mirrors.kernel.org/fedora/development/rawhide/Everything/source/tree/Packages/g/golang-${go_version}.src.rpm  \
	&& cd /root/rpmbuild/RPMS/x86_64 && rpm -Uvh --force golang-*.rpm ../noarch/golang-src-*.rpm
