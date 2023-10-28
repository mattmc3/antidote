---
title: antidote-init
section: 1
header: Antidote Manual
---

# NAME

**antidote init** - initialize the shell for dynamic bundles

# SYNOPSIS

| source <(antidote init)

# DESCRIPTION

**antidote-init** changes how the **antidote** command works by causing **antidote bundle** to automatically source its own output instead of just generating the Zsh script for a static file.

This behavior exists mainly to support legacy antigen/antibody usage. Static bundling is highly recommended for the best performance. However, dynamic bundling may be preferable for some scenarios, so you can rely on this functionality remaining a key feature in **antidote** to support users preferring dynamic bundles.

Typical usage involves adding this snippet to your **.zshrc** before using **antidote bundle** commands:

|  source <(antidote init)

# OPTIONS

-h, \--help
:   Show the help documentation.
