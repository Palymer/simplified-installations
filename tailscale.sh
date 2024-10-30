```sh
#!/bin/sh

set -eu

main() {
	OS=""
	VERSION=""
	PACKAGETYPE=""
	APT_KEY_TYPE=""
	APT_SYSTEMCTL_START=false
	TRACK="${TRACK:-stable}"

	case "$TRACK" in
		stable|unstable)
			;;
		*)
			echo "unsupported track $TRACK"
			exit 1
			;;
	esac

	if [ -f /etc/os-release ]; then
		. /etc/os-release
		case "$ID" in
			ubuntu|pop|neon|zorin|tuxedo)
				OS="ubuntu"
				if [ "${UBUNTU_CODENAME:-}" != "" ]; then
				    VERSION="$UBUNTU_CODENAME"
				else
				    VERSION="$VERSION_CODENAME"
				fi
				PACKAGETYPE="apt"
				if expr "$VERSION_ID" : "2.*" >/dev/null; then
					APT_KEY_TYPE="keyring"
				else
					APT_KEY_TYPE="legacy"
				fi
				;;
			debian)
				OS="$ID"
				VERSION="$VERSION_CODENAME"
				PACKAGETYPE="apt"
				if [ -z "${VERSION_ID:-}" ]; then
					APT_KEY_TYPE="keyring"
				elif [ "$VERSION_ID" -lt 11 ]; then
					APT_KEY_TYPE="legacy"
				else
					APT_KEY_TYPE="keyring"
				fi
				;;
			linuxmint)
				if [ "${UBUNTU_CODENAME:-}" != "" ]; then
				    OS="ubuntu"
				    VERSION="$UBUNTU_CODENAME"
				elif [ "${DEBIAN_CODENAME:-}" != "" ]; then
				    OS="debian"
				    VERSION="$DEBIAN_CODENAME"
				else
				    OS="ubuntu"
				    VERSION="$VERSION_CODENAME"
				fi
				PACKAGETYPE="apt"
				if [ "$VERSION_ID" -lt 5 ]; then
					APT_KEY_TYPE="legacy"
				else
					APT_KEY_TYPE="keyring"
				fi
				;;
			elementary)
				OS="ubuntu"
				VERSION="$UBUNTU_CODENAME"
				PACKAGETYPE="apt"
				if [ "$VERSION_ID" -lt 6 ]; then
					APT_KEY_TYPE="legacy"
				else
					APT_KEY_TYPE="keyring"
				fi
				;;
			parrot|mendel)
				OS="debian"
				PACKAGETYPE="apt"
				if [ "$VERSION_ID" -lt 5 ]; then
					VERSION="buster"
					APT_KEY_TYPE="legacy"
				else
					VERSION="bullseye"
					APT_KEY_TYPE="keyring"
				fi
				;;
			galliumos)
				OS="ubuntu"
				PACKAGETYPE="apt"
				VERSION="bionic"
				APT_KEY_TYPE="legacy"
				;;
			pureos|kaisen)
				OS="debian"
				PACKAGETYPE="apt"
				VERSION="bullseye"
				APT_KEY_TYPE="keyring"
				;;
			raspbian)
				OS="$ID"
				VERSION="$VERSION_CODENAME"
				PACKAGETYPE="apt"
				if [ "$VERSION_ID" -lt 11 ]; then
					APT_KEY_TYPE="legacy"
				else
					APT_KEY_TYPE="keyring"
				fi
				;;
			kali)
				OS="debian"
				PACKAGETYPE="apt"
				YEAR="$(echo "$VERSION_ID" | cut -f1 -d.)"
				APT_SYSTEMCTL_START=true
				if [ "$YEAR" -lt 2021 ]; then
					VERSION="buster"
					APT_KEY_TYPE="legacy"
				else
					VERSION="bullseye"
					APT_KEY_TYPE="keyring"
				fi
				;;
			Deepin)
				OS="debian"
				PACKAGETYPE="apt"
				if [ "$VERSION_ID" -lt 20 ]; then
					APT_KEY_TYPE="legacy"
					VERSION="buster"
				else
					APT_KEY_TYPE="keyring"
					VERSION="bullseye"
				fi
				;;
			centos)
				OS="$ID"
				VERSION="$VERSION_ID"
				PACKAGETYPE="dnf"
				if [ "$VERSION" = "7" ]; then
					PACKAGETYPE="yum"
				fi
				;;
			ol)
				OS="oracle"
				VERSION="$(echo "$VERSION_ID" | cut -f1 -d.)"
				PACKAGETYPE="dnf"
				if [ "$VERSION" = "7" ]; then
					PACKAGETYPE="yum"
				fi
				;;
			rhel)
				OS="$ID"
				VERSION="$(echo "$VERSION_ID" | cut -f1 -d.)"
				PACKAGETYPE="dnf"
				if [ "$VERSION" = "7" ]; then
					PACKAGETYPE="yum"
				fi
				;;
			fedora)
				OS="$ID"
				VERSION=""
				PACKAGETYPE="dnf"
				;;
			rocky|almalinux|nobara|openmandriva|sangoma|risios|cloudlinux|alinux|fedora-asahi-remix)
				OS="fedora"
				VERSION=""
				PACKAGETYPE="dnf"
				;;
			amzn)
				OS="amazon-linux"
				VERSION="$VERSION_ID"
				PACKAGETYPE="yum"
				;;
			xenenterprise)
				OS="centos"
				VERSION="$(echo "$VERSION_ID" | cut -f1 -d.)"
				PACKAGETYPE="yum"
				;;
			opensuse-leap|sles)
				OS="opensuse"
				VERSION="leap/$VERSION_ID"
				PACKAGETYPE="zypper"
				;;
			opensuse-tumbleweed)
				OS="opensuse"
				VERSION="tumbleweed"
				PACKAGETYPE="zypper"
				;;
			sle-micro-rancher)
				OS="opensuse"
				VERSION="leap/15.4"
				PACKAGETYPE="zypper"
				;;
			arch|archarm|endeavouros|blendos|garuda|archcraft)
				OS="arch"
				VERSION=""
				PACKAGETYPE="pacman"
				;;
			manjaro|manjaro-arm)
				OS="manjaro"
				VERSION=""
				PACKAGETYPE="pacman"
				;;
			alpine)
				OS="$ID"
				VERSION="$VERSION_ID"
				PACKAGETYPE="apk"
				;;
			postmarketos)
				OS="alpine"
				VERSION="$VERSION_ID"
				PACKAGETYPE="apk"
				;;
			nixos)
				echo "Please add Tailscale to your NixOS configuration directly:"
				echo
				echo "services.tailscale.enable = true;"
				exit 1
				;;
			void)
				OS="$ID"
				VERSION=""
				PACKAGETYPE="xbps"
				;;
			gentoo)
				OS="$ID"
				VERSION=""
				PACKAGETYPE="emerge"
				;;
			freebsd)
				OS="$ID"
				VERSION="$(echo "$VERSION_ID" | cut -f1 -d.)"
				PACKAGETYPE="pkg"
				;;
			osmc)
				OS="debian"
				PACKAGETYPE="apt"
				VERSION="bullseye"
				APT_KEY_TYPE="keyring"
				;;
			photon)
				OS="photon"
				VERSION="$(echo "$VERSION_ID" | cut -f1 -d.)"
				PACKAGETYPE="tdnf"
				;;
		esac
	fi

	if [ -z "$OS" ]; then
		if type uname >/dev/null 2>&1; then
			case "$(uname)" in
				FreeBSD)
					OS="freebsd"
					VERSION="$(freebsd-version | cut -f1 -d.)"
					PACKAGETYPE="pkg"
					;;
				OpenBSD)
					OS="openbsd"
					VERSION="$(uname -r)"
					PACKAGETYPE=""
					;;
				Darwin)
					OS="macos"
					VERSION="$(sw_vers -productVersion | cut -f1-2 -d.)"
					PACKAGETYPE="appstore"
					;;
				Linux)
					OS="other-linux"
					VERSION=""
					PACKAGETYPE=""
					;;
			esac
		fi
	fi

	CURL=
	if type wget >/dev/null; then
		CURL="wget -q -O-"
	fi
	if [ -z "$CURL" ]; then
		echo "The installer needs either curl or wget to download files."
		echo "Please install either curl or wget to proceed."
		exit 1
	fi

	TEST_URL="https://pkgs.tailscale.com/"
	RC=0
	TEST_OUT=$($CURL "$TEST_URL" 2>&1) || RC=$?
	if [ $RC != 0 ]; then
		echo "The installer cannot reach $TEST_URL"
		echo "Please make sure that your machine has internet access."
		echo "Test output:"
		echo $TEST_OUT
		exit 1
	fi

	OS_UNSUPPORTED=
	case "$OS" in
		ubuntu|debian|raspbian|centos|oracle|rhel|amazon-linux|opensuse|photon)
			URL="https://pkgs.tailscale.com/$TRACK/$OS/$VERSION/installer-supported"
			$CURL "$URL" 2> /dev/null | grep -q OK || OS_UNSUPPORTED=1
			;;
		fedora)
			;;
		arch)
			;;
		manjaro)
			;;
		alpine)
			;;
		void)
			;;
		gentoo)
			;;
		freebsd)
			if [ "$VERSION" != "12" ] && [ "$VERSION" != "13" ]; then
				OS_UNSUPPORTED=1
			fi
			;;
		openbsd)
			OS_UNSUPPORTED=1
			;;
		macos)
			;;
		other-linux)
			OS_UNSUPPORTED=1
			;;
		*)
			OS_UNSUPPORTED=1
			;;
	esac
	if [ "$OS_UNSUPPORTED" = "1" ]; then
		case "$OS" in
			other-linux)
				echo "Couldn't determine what kind of Linux is running."
				echo "You could try the static binaries at:"
				echo "https://pkgs.tailscale.com/$TRACK/#static"
				;;
			"")
				echo "Couldn't determine what operating system you're running."
				;;
			*)
				echo "$OS $VERSION isn't supported by this script yet."
				;;
		esac
		echo
		echo "If you'd like us to support your system better, please email support@tailscale.com"
		echo "and tell us what OS you're running."
		echo
		echo "Please include the following information we gathered from your system:"
		echo
		echo "OS=$OS"
		echo "VERSION=$VERSION"
		echo "PACKAGETYPE=$PACKAGETYPE"
		if type uname >/dev/null 2>&1; then
			echo "UNAME=$(uname -a)"
		else
			echo "UNAME="
		fi
		echo
		if [ -f /etc/os-release ]; then
			cat /etc/os-release
		else
			echo "No /etc/os-release"
		fi
		exit 1
	fi

	CAN_ROOT=
	SUDO=
	if [ "$(id -u)" = 0 ]; then
		CAN_ROOT=1
		SUDO=""
	elif type sudo >/dev/null; then
		CAN_ROOT=1
		SUDO="sudo"
	elif type doas >/dev/null; then
		CAN_ROOT=1
		SUDO="doas"
	fi
	if [ "$CAN_ROOT" != "1" ]; then
		echo "This installer needs to run commands as root."
		echo "We tried looking for 'sudo' and 'doas', but couldn't find them."
		echo "Either re-run this script as root, or set up sudo/doas."
		exit 1
	fi

	OSVERSION="$OS"
	[ "$VERSION" != "" ] && OSVERSION="$OSVERSION $VERSION"
	echo "Installing Tailscale for $OSVERSION, using method $PACKAGETYPE"
	case "$PACKAGETYPE" in
		apt)
			export DEBIAN_FRONTEND=noninteractive
			if [ "$APT_KEY_TYPE" = "legacy" ] && ! type gpg >/dev/null; then
				$SUDO apt-get update
				$SUDO apt-get install -y gnupg
			fi

			set -x
			$SUDO mkdir -p --mode=0755 /usr/share/keyrings
			case "$APT_KEY_TYPE" in
				legacy)
					$CURL "https://pkgs.tailscale.com/$TRACK/$OS/$VERSION.asc" | $SUDO apt-key add -
					$CURL "https://pkgs.tailscale.com/$TRACK/$OS/$VERSION.list" | $SUDO tee /etc/apt/sources.list.d/tailscale.list
				;;
				keyring)
					$CURL "https://pkgs.tailscale.com/$TRACK/$OS/$VERSION.noarmor.gpg" | $SUDO tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
					$CURL "https://pkgs.tailscale.com/$TRACK/$OS/$VERSION.tailscale-keyring.list" | $SUDO tee /etc/apt/sources.list.d/tailscale.list
				;;
			esac
			$SUDO apt-get update
			$SUDO apt-get install -y tailscale tailscale-archive-keyring
			if [ "$APT_SYSTEMCTL_START" = "true" ]; then
				$SUDO systemctl enable --now tailscaled
				$SUDO systemctl start tailscaled
			fi
			set +x
		;;
		yum)
			set -x
			$SUDO yum install yum-utils -y
			$SUDO yum-config-manager -y --add-repo "https://pkgs.tailscale.com/$TRACK/$OS/$VERSION/tailscale.repo"
			$SUDO yum install tailscale -y
			$SUDO systemctl enable --now tailscaled
			set +x
		;;
		dnf)
			DNF_VERSION="3"
			if dnf --version | grep -q '^dnf5 version'; then
				DNF_VERSION="5"
			fi

			if [ "$DNF_VERSION" = "5" ]; then
				set -x
				$SUDO dnf install -y 'dnf-command(config-manager)' && DNF_HAVE_CONFIG_MANAGER=1 || DNF_HAVE_CONFIG_MANAGER=0
				set +x

				if [ "$DNF_HAVE_CONFIG_MANAGER" != "1" ]; then
					if type dnf-3 >/dev/null; then
						DNF_VERSION="3"
					else
						echo "dnf 5 detected, but 'dnf-command(config-manager)' not available and dnf-3 not found"
						exit 1
					fi
				fi
			fi

			set -x
			if [ "$DNF_VERSION" = "3" ]; then
				$SUDO dnf install -y 'dnf-command(config-manager)'
				$SUDO dnf config-manager --add-repo "https://pkgs.tailscale.com/$TRACK/$OS/$VERSION/tailscale.repo"
			elif [ "$DNF_VERSION" = "5" ]; then
				$SUDO dnf config-manager addrepo --from-repofile="https://pkgs.tailscale.com/$TRACK/$OS/$VERSION/tailscale.repo"
			else
				echo "unexpected: unknown dnf version $DNF_VERSION"
				exit 1
			fi
			$SUDO dnf install -y tailscale
			$SUDO systemctl enable --now tailscaled
			set +x
		;;
		tdnf)
			set -x
			wget -fsSL "https://pkgs.tailscale.com/$TRACK/$OS/$VERSION/tailscale.repo" > /etc/yum.repos.d/tailscale.repo
			$SUDO tdnf install -y tailscale
			$SUDO systemctl enable --now tailscaled
			set +x
		;;
		zypper)
			set -x
			$SUDO rpm --import "https://pkgs.tailscale.com/$TRACK/$OS/$VERSION/repo.gpg"
			$SUDO zypper --non-interactive ar -g -r "https://pkgs.tailscale.com/$TRACK/$OS/$VERSION/tailscale.repo"
			$SUDO zypper --non-interactive --gpg-auto-import-keys refresh
			$SUDO zypper --non-interactive install tailscale
			$SUDO systemctl enable --now tailscaled
			set +x
			;;
		pacman)
			set -x
			$SUDO pacman -S tailscale --noconfirm
			$SUDO systemctl enable --now tailscaled
			set +x
			;;
		pkg)
			set -x
			$SUDO pkg install tailscale
			$SUDO service tailscaled enable
			$SUDO service tailscaled start
			set +x
			;;
		apk)
			set -x
			if ! grep -Eq '^http.*/community$' /etc/apk/repositories; then
				if type setup-apkrepos >/dev/null; then
					$SUDO setup-apkrepos -c -1
				else
					echo "installing tailscale requires the community repo to be enabled in /etc/apk/repositories"
					exit 1
				fi
			fi
			$SUDO apk add tailscale
			$SUDO rc-update add tailscale
			$SUDO rc-service tailscale start
			set +x
			;;
		xbps)
			set -x
			$SUDO xbps-install tailscale -y
			set +x
			;;
		emerge)
			set -x
			$SUDO emerge --ask=n net-vpn/tailscale
			set +x
			;;
		appstore)
			set -x
			open "https://apps.apple.com/us/app/tailscale/id1475387142"
			set +x
			;;
		*)
			echo "unexpected: unknown package type $PACKAGETYPE"
			exit 1
			;;
	esac

	echo "Installation complete! Log in to start using Tailscale by running:"
	echo
	if [ -z "$SUDO" ]; then
		echo "tailscale up"
	else
		echo "$SUDO tailscale up"
	fi
}

main
```
