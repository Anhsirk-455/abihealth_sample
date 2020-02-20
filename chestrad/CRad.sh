#!/bin/bash

CHESTRAD_INSTALL_DIR="$HOME/chest_rad"
CONDA_INSTALL_DIR="$HOME/miniconda3"

usage(){
	echo "Usage: $0 [ install/uninstall/re-install ]"
	echo "Please specify an option"
	echo ""
	echo "Example: $0 install"
	exit 2
}

line_break(){
	echo ""
}

die(){
    local message="$1"
    local exitCode=$2
    echo "$message"
    [ "$exitCode" == "" ] && exit 1 || exit $exitCode
}

pretty_print(){
	echo -e "[*]  $1"
}

is_user_root(){
	[ "$(id -u)" != "0" ] && die "You must be root to run this script" 2
}

install_conda(){
	pretty_print "Installing Miniconda with DEFAULT settings!"
	bash ./miniconda3.sh -b -p $CONDA_INSTALL_DIR -u
	echo export PATH=${CONDA_INSTALL_DIR}'/bin/:$PATH' >> ~/.bashrc
	export PATH=${CONDA_INSTALL_DIR}/bin/:$PATH
	source ~/.bashrc
	conda --version &> /dev/null
	if [ $? -eq 0 ]; then
		pretty_print "conda installed successfully"
	fi
}

download_conda(){
	arch=$(uname -i)
	pretty_print "Checking the system Architecture"
	if [ "$arch" == "x86_64" ]; then
		pretty_print "Found x86_64 Architecture"
		pretty_print "Downloading Latest Miniconda for this system"
		line_break
		wget -c https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda3.sh
		line_break

	else
		pretty_print "Found x86 Architecture"
		pretty_print "Downloading Latest Miniconda for this system"
		line_break
		wget -c https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86.sh -O miniconda3.sh
		line_break
	fi
	install_conda
}

check_and_install_conda(){
	pretty_print "Checking for 'conda'"
	conda_path=$(which conda)
	if [ -z "$conda_path" -a "$conda_path" == "" ]; then
		pretty_print "conda NOT FOUND!"
		download_conda
	else
		#Remove everything from string after and including "bin"
		CONDA_INSTALL_DIR=${conda_path%bin*}
		pretty_print "conda installation FOUND in $CONDA_INSTALL_DIR"
	fi
}

uninstall_conda(){
	echo "Note: This will remove all packages installed with anaconda/miniconda"
	echo -ne "Full uninstall [y/n]: "
	read inp
	if [ "$inp" == "y" ]; then
		pretty_print "Uninstalling Conda..."
		for DIRECTORY in miniconda3 .condarc .conda .continuum; do
			if [ -d "$HOME/$DIRECTORY" ]; then
				pretty_print "Removing $HOME/$DIRECTORY.."
		  		rm -rf $HOME/$DIRECTORY
			fi
		done
		if [ -d $CONDA_INSTALL_DIR ]; then
			pretty_print "Removing $CONDA_INSTALL_DIR"
			rm -rf $CONDA_INSTALL_DIR
		fi
		echo "Uninstalling CHESTRAD..."
		if [ -d $CHESTRAD_INSTALL_DIR ]; then
			pretty_print "Removing $CHESTRAD_INSTALL_DIR"
			rm -rf $CHESTRAD_INSTALL_DIR
		fi
		pretty_print "Done!"
	else
		echo "Skipping uninstallation"
	fi
}

add_path(){
    for DIRECTORY in miniconda3 anaconda3 anaconda miniconda; do
		if [ -d "$HOME/$DIRECTORY/bin" ]; then
			export PATH=$PATH:$HOME/$DIRECTORY/bin/
		fi
	done
}

function version_check() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

check_and_install_git(){
	pretty_print "Checking for git"
	git --version &> /dev/null
	if [ $? -eq 127 ]; then
		pretty_print "git NOT FOUND!"
		pretty_print "Installing git"
		apt-get install git
	else
		pretty_print "git FOUND!"
		allowed_git_version=1.19.0
		system_git_version=$(git --version)
		if version_check $system_git_version $allowed_git_version; then
		     pretty_print "git version OK!"
		fi
	fi
}

install_libraries(){
	if [ ! -d $CHESTRAD_INSTALL_DIR ]; then
		mkdir -p $CHESTRAD_INSTALL_DIR
	fi
	cd $CHESTRAD_INSTALL_DIR
	sudo apt-get update && sudo apt-get install -y libsm6 libxext6 libxrender1 libgl1
	if [ -f $(pwd)/crad_api/old/crad_api/conv_learner.py ]; then
		pretty_print "crad_api is already downloaded!"
		pretty_print "Updating.."
		line_break
		cd crad_api
		git pull origin master
		cd ..
	else 
		pretty_print "Downloading crad_api"
		git clone https://github.com/chestrad_attunelive/crad_api.git
	fi
	if [ -f $(pwd)/chestrad/crxapi.py ]; then
		pretty_print "Found chestrad ML-API.."
		pretty_print "Updating..."
		line_break
		cd chestrad
		git pull origin branch2
		cd ..
	else
		pretty_print "Downloading chestrad ML-API"
		git clone -b branch2 --single-branch https://gitlab.com/chestrad_attunelive/chestrad.git
	fi
	pretty_print "Creating crad-cpu Environment"
	if [ -f chestrad/env.yml ]; then
		conda env create -f chestrad/env.yml
	else
		die "Was not able to find the environment configuration...!!" 2
	fi
	if [ -f $CHESTRAD_INSTALL_DIR/chestrad/weights/resnext_50_32x4d.pth ]; then
		mkdir -p $CHESTRAD_INSTALL_DIR/card_api/old/card_api/weights
		mv $CHESTRAD_INSTALL_DIR/chestrad/weights/resnext_50_32x4d.pth $CHESTRAD_INSTALL_DIR/card_api/old/card_api/weights/
	fi
	pretty_print "Linking card_api to current environment"
	site_packages_dir=$(find $CONDA_INSTALL_DIR/envs/card-cpu/ -type d -name "site-packages" 2> /dev/null -exec sh -c 'printf "%s\n" "$1"; kill "$PPID"' sh {} \;)
	ln -sf $CHESTRAD_INSTALL_DIR/card_api/old/card_api ${site_packages_dir}/card_api
	if [ $? -eq 0 ]; then
		pretty_print "Done!!"
	else
		echo "Linking Failed"
	fi
}

install_chestrad(){
	check_and_install_conda
	check_and_install_git
	install_libraries
}

check_input_params(){
	case "$1" in 
	  install|uninstall|re-install|update)
	  ;;
	  *)
	         echo "[!] Invalid option: $1"
	         exit 2
	  ;;
	esac
}

perform_requested_task(){
	case "$1" in
		install)
			echo "Installing CHESTRAD!"
			line_break
			install_chestrad			
			;;
		uninstall)
			uninstall_conda
			line_break
			;;
		re-install)
			echo "Re-Installing CHESTRAD"
			line_break
			perform_requested_task uninstall
			perform_requested_task install
			;;
		update)
			echo "Updating CHESTRAD"
			line_break
		;;
	esac
}

# # ---- Actual sequence of steps ----
# #checking for valid number of options
[ $# -eq 0 ] && usage && die "" 2


# #checking for root permissions
is_user_root

check_and_install_git
# # checking for correct input params 
check_input_params $1

# #perform the specified task
perform_requested_task $1



