() {
  setopt interactivecomments
  typeset -ga grizwold_zopts=(
    noaliases
    aliasfuncdef
    allexport
    noalwayslastprompt
    alwaystoend
    appendcreate
    noappendhistory
    autocd
    autocontinue
    noautolist
    noautomenu
    autonamedirs
    noautoparamkeys
    noautoparamslash
    autopushd
    noautoremoveslash
    autoresume
    nobadpattern
    nobanghist
    nobareglobqual
    bashautolist
    bashrematch
    nobeep
    nobgnice
    braceccl
    bsdecho
    nocaseglob
    nocasematch
    cbases
    cdablevars
    cdsilent
    chasedots
    chaselinks
    nocheckjobs
    nocheckrunningjobs
    # noclobber
    combiningchars
    completealiases
    completeinword
    continueonerror
    correct
    correctall
    cprecedences
    cshjunkiehistory
    cshjunkieloops
    cshjunkiequotes
    cshnullcmd
    cshnullglob
    nodebugbeforecmd
    dvorak
    emacs
    noequals
    # errexit
    # errreturn
    noevallineno
    # noexec
    extendedglob
    extendedhistory
    noflowcontrol
    # forcefloat
    nofunctionargzero
    noglob
    noglobalexport
    # noglobalrcs
    globassign
    globcomplete
    globdots
    globstarshort
    globsubst
    nohashcmds
    nohashdirs
    hashexecutablesonly
    nohashlistall
    histallowclobber
    nohistbeep
    histexpiredupsfirst
    histfcntllock
    histfindnodups
    histignorealldups
    histignoredups
    histignorespace
    histlexwords
    histnofunctions
    histnostore
    histreduceblanks
    nohistsavebycopy
    histsavenodups
    histsubstpattern
    histverify
    nohup
    ignorebraces
    ignoreclosebraces
    ignoreeof
    incappendhistory
    incappendhistorytime
    # interactive
    interactivecomments
    # ksharrays
    kshautoload
    kshglob
    # kshoptionprint
    kshtypeset
    kshzerosubscript
    nolistambiguous
    nolistbeep
    listpacked
    listrowsfirst
    nolisttypes
    localloops
    # localoptions
    localpatterns
    localtraps
    # login
    longlistjobs
    magicequalsubst
    mailwarning
    markdirs
    menucomplete
    # monitor
    nomultibyte
    nomultifuncdef
    nomultios
    nonomatch
    nonotify
    nullglob
    numericglobsort
    octalzeroes
    overstrike
    pathdirs
    pathscript
    pipefail
    posixaliases
    posixargzero
    posixbuiltins
    posixcd
    posixidentifiers
    posixjobs
    # posixstrings
    posixtraps
    printeightbit
    printexitvalue
    # privileged
    promptbang
    nopromptcr
    # nopromptpercent
    nopromptsp
    promptsubst
    pushdignoredups
    pushdminus
    pushdsilent
    pushdtohome
    rcexpandparam
    rcquotes
    # norcs
    recexact
    rematchpcre
    # restricted
    rmstarsilent
    rmstarwait
    sharehistory
    shfileexpansion
    shglob
    # shinstdin
    shnullcmd
    shoptionletters
    noshortloops
    shwordsplit
    # singlecommand
    singlelinezle
    # sourcetrace
    sunkeyboardhack
    transientrprompt
    trapsasync
    typesetsilent
    nounset
    # verbose
    # vi
    warncreateglobal
    warnnestedvar
    # xtrace
    # zle
  )
  setopt $grizwold_zopts
}
