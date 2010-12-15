# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# (C) 2010 Red Hat, Inc.
# All rights reserved.
# END COPYRIGHT BLOCK


###############################################################################
###                       P A C K A G E   H E A D E R                       ###
###############################################################################

Name:             pki-migrate
Version:          9.0.0
Release:          1%{?dist}
Summary:          Red Hat Certificate System - PKI Migration Scripts
URL:              http://pki.fedoraproject.org/
License:          GPLv2
Group:            System Environment/Base

# Suppress automatic 'requires' and 'provisions' of multi-platform 'binaries'
AutoReqProv:      no

BuildArch:        noarch

BuildRoot:        %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildRequires:    cmake
BuildRequires:    java-devel >= 1:1.6.0
BuildRequires:    jpackage-utils

Requires:         java >= 1:1.6.0

Source0:          http://pki.fedoraproject.org/pki/sources/%{name}/%{name}-%{version}.tar.gz

%global _binaries_in_noarch_packages_terminate_build   0

%description
Red Hat Certificate System (CS) is an enterprise software system designed
to manage enterprise Public Key Infrastructure (PKI) deployments.

PKI Migration Scripts are used to export data from previous versions of
Netscape Certificate Management Systems, iPlanet Certificate Management
Systems, and Red Hat Certificate Systems into a flat-file which may then
be imported into this release of Red Hat Certificate System.

Note that since this utility is platform-independent, it is generally possible
to migrate data from previous PKI deployments originally stored on other
hardware platforms as well as earlier versions of this operating system.


%prep


%setup -q


%clean
%{__rm} -rf %{buildroot}


%build
%{__mkdir_p} build
cd build
%cmake -DVAR_INSTALL_DIR:PATH=/var -DBUILD_PKI_MIGRATE:BOOL=ON ..
%{__make} VERBOSE=1 %{?_smp_mflags}


%install
%{__rm} -rf %{buildroot}
cd build
%{__make} install DESTDIR=%{buildroot}


%files
%defattr(-,root,root,-)
%doc base/migrate/LICENSE
%dir %{_datadir}/pki/migrate
%{_datadir}/pki/migrate/*


%changelog
* Wed Dec 1 2010 Matthew Harmsen <mharmsen@redhat.com> 9.0.0-1
- Initial revision. (kwright@redhat.com & mharmsen@redhat.com)
