qubes-test-mirage
=================

These scripts can be used to test Mirage unikernels on Qubes. They
provide a secure way to transfer the image to dom0 and run it. Hopefully.

First, use `qubes-manager` to create a new AppVM called `mirage-test`.
You can make it standalone or not and use any template (it doesn't matter
because unikernels already contain all their code and don't need to use a disk
to boot).

Next, still in dom0, create a new `mirage-test` kernel, with an empty `modules.img` and `vmlinuz` and a compressed empty file for the initramfs, and then set that as the kernel for the new VM:

    # mkdir /var/lib/qubes/vm-kernels/mirage-test
    # cd /var/lib/qubes/vm-kernels/mirage-test
    # touch modules.img
    # touch vmlinuz
    # cat /dev/null | gzip > initramfs
    # touch test-mirage-ok
    # qvm-prefs -s mirage-test kernel mirage-test

Only kernels with a `test-mirage-ok` file can be updated using this program.

Build the test-mirage binaries:

    $ make

The default make target uses Docker to build statically-linking binaries, which ensures
they will work with the version of Fedora in dom0. You can also use `make local` to build
without Docker, but you'll need to use a compatible version of glibc in that case.

This will generate two binaries in the `_build/default` directory:

- `dom0.exe` will run in dom0 and accepts kernel uploads.
- `dev.exe` will run in your dev VM and sends kernel images to dom0.

Copy `dom0.exe` to dom0 as `/usr/local/bin/test-mirage-dom0` (and make it executable).
The easiest way to do this is to run these commands in dom0 (`dev` is the name of the build VM
and you'll need to adjust the path):

    # qvm-run -p dev 'cat /path/to/test-mirage/_build/default/dom0.exe' > dom0.exe
    # mv dom0.exe /usr/local/bin/test-mirage-dom0
    # chmod a+x /usr/local/bin/test-mirage-dom0

Create `/etc/qubes-rpc/talex5.TestMirage` containing just that path:

    # echo /usr/local/bin/test-mirage-dom0 > /etc/qubes-rpc/talex5.TestMirage

Create a policy allowing your `dev` VM to use the service, as `/etc/qubes-rpc/policy/talex5.TestMirage`:

    # cat > /etc/qubes-rpc/policy/talex5.TestMirage << EOF
    dev dom0 allow
    \$anyvm	\$anyvm	deny
    EOF

The policy says that `dev` (your dev VM) can use the `talex5.TestMirage` service in `dom0`.

Then you can test any Mirage image with the `test-mirage` script, e.g.

    $ /path/to/test-mirage/test-mirage mir-console.xen mirage-test
    Waiting for 'Ready'... OK
    Uploading 'mir-console.xen' (4184144 bytes) to "mirage-test"
    Waiting for 'Booting'... OK
    ERROR: VM already stopped!
    --> Creating volatile image: /var/lib/qubes/appvms/mirage-test/volatile.img...
    --> Loading the VM (type = AppVM)...
    --> Starting Qubes DB...
    --> Setting Qubes DB info for the VM...
    --> Updating firewall rules...
    --> Starting the VM...
    MirageOS booting...
    Initialising timer interface
    Initialising console ... done.
    hello
    world
    ...

Note: the `ERROR: VM already stopped!` line is because it tries to stop any existing VM first, and this gets printed if it isn't already running.

Once started, the test VM console is attached using `sudo xl console -c`, with stdin and stdout connected to the process in your dev VM.
I am assuming that this command does not provide a way to escape from the VM by entering some special character sequence (the usual `Ctrl-]` does not work since this is not a tty, and would just end the process in any case).

Note: Your unikernel should implement the qrexec protocol so that Qubes can control it with `qvm-run`. See [qubes-mirage-skeleton][] for an example unikernel that does this. Alternatively, you can configure with `mirage configure -t qubes` to have this set up automatically.


LICENSE
-------

Copyright (c) 2015, Thomas Leonard
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[qubes-mirage-skeleton]: https://github.com/talex5/qubes-mirage-skeleton
