qubes-test-mirage
=================

These **experimental** scripts can be used to test Mirage unikernels on Qubes. They
provide a secure way to transfer the image to dom0 and run it. Hopefully.

In dom0, create a directory `/var/lib/test-mirage/` and add your test configuration:

    name = 'mirage-test'
    kernel = '/var/lib/test-mirage/mir-test.xen'
    builder = 'linux'
    memory = 16
    on_crash = 'preserve'
    disk = []
    vif = []

Copy `dom0.native` to dom0 as `/usr/local/bin/test-mirage-dom0`.
Create `/etc/qubes-rpc/talex5.TestMirage` containing just that path.
Create a policy allowing your `dev` VM to use the service, as `/etc/qubes-rpc/policy/talex5.TestMirage`.

In your development domU, create a script called `test-mirage` containing:

    #!/bin/sh
    exec qrexec-client-vm dom0 talex5.TestMirage /path/to/test-mirage/dev.native "$@"

Then you can test any Mirage image with e.g.

    $ test-mirage mir-console.xen
    Waiting for 'Ready'... OK
    Uploading 'mir-console.xen' (3969544 bytes)
    Waiting for 'Booting'... OK
    mirage-test is an invalid domain identifier (rc=-6)
    ...
    hello
    world

Note: the `mirage-test is an invalid domain identifier` line is because it tries to `xl destroy mirage-test` first, and this gets printing if it isn't already running.

The test VM is run using `sudo xl create -c`, with stdin and stdout connected to the process in your dev VM.
I am assuming that this command does not provide a way to escape from the VM by entering some special character sequence (the usual `Ctrl-]` does not work since this is not a tty, and would just end the process in any case).


LICENSE
-------

Copyright (c) 2015, Thomas Leonard
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
