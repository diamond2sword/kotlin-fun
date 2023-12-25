#!/bin/bash

main () {
	apt update && apt upgrade
	pkg --check-mirror upgrade
	apt install vim git expect gradle openssh
	add_syntax_highlighting
	add_bash_completion
	edit_vim_settings
	create_project_maker
	clone_kotlin_repo
}

clone_kotlin_repo () {
	cd $HOME
	git clone https://github.com/diamond2sword/kotlin-fun
}

create_project_maker () {
	echo "$PROJECT_MAKER" > $HOME/new_project.sh
	chmod +x $HOME/new_project.sh
	rm $HOME/../usr/bin/new_project.sh
	ln -s $HOME/new_project.sh $HOME/../usr/bin/new_project.sh
}

edit_vim_settings () {
cat << "EOF" >> $HOME/../usr/share/vim/vimrc
	set tabstop=4 shiftwidth=4
EOF
}

add_bash_completion () {
	mkdir $HOME/bash_completion.d
	curl -LA gradle-completion https://edub.me/gradle-completion-bash -o $HOME/bash_completion.d/gradle-completion.bash
	touch $HOME/.bashrc
	echo 'for completion_script in $HOME/bash_completion.d/*; { source $completion_script; }' >> $HOME/.bashrc
}

add_syntax_highlighting () {
	git clone https://github.com/udalov/kotlin-vim.git $HOME/.vim/pack/plugins/start/kotlin-vim
}

PROJECT_MAKER=$(cat << "EOF"
#!/bin/bash
main () {
	start_gradle_daemon
	create_project
	change_kotlin_version
	create_package_link
	create_main_class
	change_main_class
	run_project
}

run_project () (
	echo -e "\n\nRunning '$PROJECT_NAME'..."
	cd $PROJECT_DIR
	./gradlew run
)

create_package_link () {
	echo -e "\n\nCreating link $PROJECT_NAME/$PROJECT_NAME..."
	rm $PROJECT_DIR/$PROJECT_NAME
	ln -s $PROJECT_DIR/app/src/main/kotlin/* $PROJECT_DIR/$PROJECT_NAME
}

change_main_class () {
	append_line $PROJECT_DIR/app/build.gradle 'application{mainClass="${rootProject.name}.MainKt"} //SED' SED_MAIN_CLASS
}

create_main_class () {
	echo "$(get_main_class)" > $PROJECT_DIR/$PROJECT_NAME/Main.kt
}

change_kotlin_version () {
	while :; do {
			[[ "$(cat $PROJECT_DIR/app/build.gradle 2>/dev/null)" ]] && break
	} done
	append_line $PROJECT_DIR/app/build.gradle 'dependencies{implementation "org.jetbrains.kotlin:kotlin-stdlib:1.3.72"}' SED_KOTLIN_VERSION
}

create_project () (
	mkdir -p $PROJECT_DIR
	cd $PROJECT_DIR
	do_gradle_init
)

start_gradle_daemon () {											  
	gradle --daemon
}

do_gradle_init () {
expect << "EOF2"
spawn gradle init
expect -exact "Enter selection (default: basic) \[1..4\] "
send -- "2\r"
expect -exact "Enter selection (default: Java) \[1..6\] "
send -- "4\r"
expect -exact "Enter selection (default: no - only one application project) \[1..2\] "
send -- "\r"
expect -exact "Enter selection (default: Kotlin) \[1..2\] "
send -- "1\r"
expect -exact "Generate build using new APIs and behavior (some features may change in the next minor release)? (default: no) \[yes, no\] "
send -- "\r"
expect -re {Project name \(default: .*\): }
send -- "\r"
expect -re {Source package \(default: .*\): }
send -- "\r"
EOF2
}

append_line () {
	path="$1"; shift
	line="$1"; shift
	sed_word="$1"
	sed -i "/$sed_word/d" $path
	echo "$line //$sed_word" >> $path
}

get_main_class () {
echo "package $PROJECT_NAME"
echo "$(cat << "EOF2"

fun main() {
	println("Kotlin Version: ${KotlinVersion.CURRENT}")
	println(App().greeting)
}
EOF2
)"
}

PROJECT_NAME="$1"; shift
PROJECT_BASE_DIR="$1"
PROJECT_DIR="$PROJECT_BASE_DIR/$PROJECT_NAME"
! mkdir -p $PROJECT_DIR && PROJECT_DIR="$PWD/$PROJECT_NAME" &&
! mkdir -p $PROJECT_DIR && PROJECT_DIR="$HOME/$PROJECT_NAME" &&
! mkdir -p $PROJECT_DIR

main
EOF
)

yes | main "$@"
