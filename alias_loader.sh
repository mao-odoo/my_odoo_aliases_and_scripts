##########################################################
########################  PATHS  ##########################
###########################################################

export AP=$(dirname $0)

export SRC="$HOME/src"
export ODOO="$SRC/odoo"
export ENTERPRISE="$SRC/enterprise"
export DESIGN_THEMES="$SRC/design-themes"
export INTERNAL="$SRC/internal"
export PAAS="$SRC/paas"
export ST="$SRC/support-tools"
export SRC_MULTI="$HOME/multi_src"
export USER_DOC="$SRC/documentation-user"

if [ "$OSTYPE" = "darwin19.0" ]; then
    export ODOO_STORAGE="$HOME/Library/Application Support/Odoo"
else
    export ODOO_STORAGE="$HOME/.local/Odoo"
fi

# GPG stuff
export GPG_TTY=$(tty)

# activate bash style completion
autoload bashcompinit
bashcompinit

# use vim as default editor
export EDITOR="vim"

# activate vi mode in the terminal
bindkey -v
if [ ! -f ~/.inputrc ]; then
    echo "set editing-mode vi" >~/.inputrc
else
    if ! grep -q "set editing-mode vi" ~/.inputrc; then
        echo "set editing-mode vi" >>~/.inputrc
    fi
fi

# setup .zshrc to source this file
if ! grep -q "source $0" ~/.zshrc; then
    echo "source $0" >>~/.zshrc
fi

# load all the other files in the $AP folder
source $AP/alias.sh

# load python based aliases
python3 $AP/python_scripts/python_alias_exporter.py
source $AP/autogenerated_scripts.sh

# load autocompletion scripts
source $AP/completion.sh
