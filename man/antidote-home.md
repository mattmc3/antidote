---
title: antidote-home
section: 1
header: Antidote Manual
---

# NAME

**antidote home** - print where antidote is cloning bundles

# SYNOPSIS

| antidote home

# DESCRIPTION

**antidote-home** shows you where antidote stores its cloned repos. It is not the home of the antidote utility itself.

|   antidote home

You can override antidote's default home directory by setting the _\$ANTIDOTE_HOME_ variable in your **.zshrc**.

# OPTIONS

-h, \--help
:   Show the help documentation.

# EXAMPLES

You can clear out all your cloned repos like so:

|   rm -rfi $(antidote home)
