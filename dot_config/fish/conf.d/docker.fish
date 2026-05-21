set -l brew_docker "/home/linuxbrew/.linuxbrew/bin"


if test -d "$brew_docker"
    set -gx DOCKER_PATH "$brew_docker"
else if type -q docker
    set -gx DOCKER_PATH ""
end

if set -q DOCKER_PATH
    if test -n "$DOCKER_PATH"
        if not contains "$DOCKER_PATH" $PATH
            set -gx PATH "$DOCKER_PATH" $PATH
        end
    end

    abbr -g dk docker
    abbr -g dkps 'docker ps'
    abbr -g dksp 'docker system prune'
    abbr -g dkncr 'docker network create'
    abbr -g dknl 'docker network ls'
    abbr -g dknct 'docker network connect'
end