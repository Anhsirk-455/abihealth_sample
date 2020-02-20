                ____ _   _ _____ ____ _____ ____      _    ____  
               / ___| | | | ____/ ___|_   _|  _ \    / \  |  _ \ 
              | |   | |_| |  _| \___ \ | | | |_) |  / _ \ | | | |
              | |___|  _  | |___ ___) || | |  _ <  / ___ \| |_| |
               \____|_| |_|_____|____/ |_| |_| \_\/_/   \_\____/ 
                                                                 

SETUP instructions to install CHESTRAD ML-API on a fresh linux box.

1) Installation

USAGE: sudo ./CRad.sh install

	-This instruction will:
	-Install miniconda, git if not present in PATH
	-Then clones the fastai, ML-API from the git. [Username and Password is required to clone ML-API]
	-Creates a conda environment named 'crad-cpu' and install required packages.
	-Links the required dependency files to the above environment.

	Note: To start the server, you can navigate to "~/chest_rad/chestrad/"
		 Then modify the port number to use in the configuration file.
		 The config file is named as 'setup.cfg'

		 Then run "./serve_model.sh". You might want to run it using nohup to keep the process alive

2) Uninstallation

USAGE: sudo ./CRad.sh uninstall

	-This will completely uninstall all the installed files including miniconda along with
	created conda environments, fastai and chestrad.

3)Re-Installation

USAGE: sudo ./CRad.sh re-install

	-This instruction will perform uninstallation and re-installation sequentially.

