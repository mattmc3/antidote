0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup

() {
  local cmd='antidote bundle $TEMP_HOME/myfile.zsh'
  echo "echo myfile" > $TEMP_HOME/myfile.zsh
  local expected=(
    "source $TEMP_HOME/myfile.zsh"
  )
  local actual=($(eval $cmd 3>/dev/null 2>/dev/null))
  @test "'$cmd' works" "$expected" = "$actual"
}

() {
  local cmd='antidote bundle $TEMP_HOME/plugins/myplugin'
  mkdir -p $TEMP_HOME/plugins/myplugin
  echo "echo myplugin" > $TEMP_HOME/plugins/myplugin/myplugin.plugin.zsh
  local expected=(
    "fpath+=( $TEMP_HOME/plugins/myplugin )"
    "source $TEMP_HOME/plugins/myplugin/myplugin.plugin.zsh"
  )
  local actual=($(eval $cmd 3>/dev/null 2>/dev/null))
  @test "'$cmd' works" "$expected" = "$actual"
}

() {
  local cmd='antidote bundle baz/ohmy path:plugins/extract'
  local expected=(
    "fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-ohmy/plugins/extract )"
    "source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-ohmy/plugins/extract/extract.plugin.zsh"
  )
  local actual=($(eval $cmd 3>/dev/null 2>/dev/null))
  @test "'$cmd' works" "$expected" = "$actual"
}

() {
  local cmd='antidote bundle baz/ohmy path:plugins/extract/extract.plugin.zsh'
  local expected=(
    "source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-ohmy/plugins/extract/extract.plugin.zsh"
  )
  local actual=($(eval $cmd 3>/dev/null 2>/dev/null))
  @test "'$cmd' works" "$expected" = "$actual"
}

() {
  local cmd='antidote bundle baz/ohmy path:lib/history.zsh'
  local expected=(
    "source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-ohmy/lib/history.zsh"
  )
  local actual=($(eval $cmd 3>/dev/null 2>/dev/null))
  @test "'$cmd' works" "$expected" = "$actual"
}

() {
  local cmd='antidote bundle baz/ohmy path:lib'
  local expected=(
    "fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-ohmy/lib )"
    "source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-ohmy/lib/clipboard.zsh"
    "source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-ohmy/lib/git.zsh"
    "source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-ohmy/lib/history.zsh"
  )
  local actual=($(eval $cmd 3>/dev/null 2>/dev/null))
  @test "'$cmd' works" "$expected" = "$actual"
}

teardown
