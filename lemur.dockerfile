FROM fedora:rawhide

RUN dnf install -y golang redhat-rpm-config git pcre-devel glibc-static which rpm-build rpmdevtools hostname procps-ng

RUN go get github.com/tools/godep

ARG go_version
ARG go_macros_version

RUN ln -s /usr/lib/rpm/macros.d/macros.go-srpm /etc/rpm/ \
	&& rpmbuild --define '%check exit 0' --rebuild http://mirrors.kernel.org/fedora/development/rawhide/Everything/source/tree/Packages/g/golang-${go_version}.src.rpm  \
	&& cd /root/rpmbuild/RPMS/x86_64 && rpm -Uvh golang-*.rpm ../noarch/golang-src-*.rpm
