VM Loop Test
============

This is a WIP script to run two VMs, whic boot, run hackbench and cyclictest
and reboots, run the same workloads again, and shuts down.

This continues in a loop until a failure is detected.

WARNING: This is very much work in progress and relies on having two VM images
in the parent diretory: ../arm64-trusty.img and ../arm64-trusty-2.img

TODO:
 - Make this portable
 - Don't rely on properies of host system
 - Make self-contained (don't rely on existing images/configuration etc.)
 - Automatically generate images required
 - Capture failures with improved diagnostics
