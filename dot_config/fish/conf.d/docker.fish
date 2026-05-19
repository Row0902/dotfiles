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

    alias dk='docker'
    alias dkps='docker ps'
    alias dksp='docker system prune'
    alias dkncr='docker network create'
    alias dknl='docker network ls'
    alias dknct='docker network connect'
end