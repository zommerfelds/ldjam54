FROM gitpod/workspace-full

RUN sudo add-apt-repository ppa:haxe/releases -y \
    && sudo apt-get update \
    && sudo apt-get install -y \
        haxe \
    && sudo rm -rf /var/lib/apt/lists/*

RUN pip install livereload

COPY --chown=gitpod:gitpod build-js.hxml /tmp
RUN mkdir -p ~/haxelib && haxelib setup ~/haxelib && yes | haxelib --quiet --always install /tmp/build-js.hxml