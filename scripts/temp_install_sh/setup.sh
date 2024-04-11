# Shell Scripting Reference:
# Link: https://tldp.org/LDP/abs/html/

function install_brew {
    # Brew Reference: https://brew.sh/
    # Homebrew Cheatsheet: https://devhints.io/homebrew
    echo "function::install_brew"
    if [[ ! $(command -v brew) ]]; then
        brew_url="https://raw.githubusercontent.com/Homebrew/install/master/install.sh"
        echo "Homebrew is not installed , downloading it"
        $(command -v sh) -c "$(curl -fsSL $brew_url)"
        else
        echo "Homebrew is already installed!"
    fi

    echo $(command -v brew)
}

function install_jdk {
    echo "function::install_jdk"
    brew install scala
    brew install sbt
    echo "Finding Shells"
    currentShell=$(ps -p $$ -ocomm=)
    echo "Your current shell is: $currentShell"

    export PATH="/usr/local/opt/openjdk/bin:$PATH"
    export CPPFLAGS="-I/usr/local/opt/openjdk/include"

    # Depending on the environment you use, you may need to update
    # your shell's boot config to persist changes
    if [[ $currentShell =~ "sh" ]]; then
        if [[ $(grep -Fxq 'export PATH="/usr/local/opt/openjdk/bin:$PATH"' ~/.bashrc) ]]; then
            echo "Appending to PATH (sh) for OpenJDK installation"
            echo 'export PATH="/usr/local/opt/openjdk/bin:$PATH"' >> ~/.bashrc
            echo 'export CPPFLAGS="-I/usr/local/opt/openjdk/include"' >> ~/.bashrc
            sudo ln -sfn /usr/local/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
        else
            echo "OpenJDK setup already complete (SH)."
        fi
        else if [[ $currentShell =~ "zsh" ]]; then
            if [[ $(grep -Fxq 'export PATH="/usr/local/opt/openjdk/bin:$PATH"' ~/.zshrc) ]]; then
                echo "Appending to PATH (zsh) for OpenJDK installation"
                echo 'export PATH="/usr/local/opt/openjdk/bin:$PATH"' >> ~/.zshrc
                echo 'export CPPFLAGS="-I/usr/local/opt/openjdk/include"' >> ~/.zshrc
                sudo ln -sfn /usr/local/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
            else
                echo "OpenJDK setup already complete (ZSH)."
            fi
        fi
    fi


    echo $($(command -v java) -version) && echo $($(command -v scala) -version)
}

function install_spark {
    # Reference: Scala Spark Setup
    # https://learnscalaspark.com/getting-started-intellij-scala-apache-spark
    # Reference: PySpark Setup
    # https://medium.com/@achilleus/get-started-with-pyspark-on-mac-using-an-ide-pycharm-b8cbad7d516f
    echo "function::install_spark"
    pkgs=("apache-spark" "python" "virtualenv")
    for i in "${pkgs[@]}"
    do
        brew install $i
    done
    # If you're creating a new virtualenv or even if you're using the one pathed on your computer, you can use pip to install pyspark
}

function install_optionals {
    echo "function::install_optionals"
    optionals=("terraform" "apache-flink" "awscli")
    for i in "${optionals[@]}"
    do
        brew install $i
    done
}

install_brew
install_jdk
install_spark
install_optionals