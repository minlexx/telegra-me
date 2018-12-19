# 
# Do NOT Edit the Auto-generated Part!
# Generated by: spectacle version 0.27
# 

Name:       harbour-telegrame

# >> macros
# << macros

%{!?qtc_qmake:%define qtc_qmake %qmake}
%{!?qtc_qmake5:%define qtc_qmake5 %qmake5}
%{!?qtc_make:%define qtc_make make}
%{?qtc_builddir:%define _builddir %qtc_builddir}
Summary:    A native Telegram client for Sailfish OS
Version:    0.9
Release:    12
Group:      Qt/Qt
License:    WTFPL
URL:        http://gitlab.unique-conception.org/sailfish-app/telegra-me
Source0:    %{name}-%{version}.tar.bz2
Source100:  harbour-telegrame.yaml
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   tdlibjson >= 1.2
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5Multimedia)
BuildRequires:  pkgconfig(openssl)
BuildRequires:  pkgconfig(tdlibjson)
BuildRequires:  desktop-file-utils

%description
Short description of my Sailfish OS Application


%prep
%setup -q -n %{name}-%{version}

# >> setup
# << setup

%build
# >> build pre
# << build pre

%qtc_qmake5 

%qtc_make %{?_smp_mflags}

# >> build post
# << build post

%install
rm -rf %{buildroot}
# >> install pre
# << install pre
%qmake5_install

# >> install post
# << install post

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
%{_datadir}/lipstick/notificationcategories/*.conf
%{_datadir}/ngfd/events.d/*.ini
# >> files
# << files
