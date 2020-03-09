# Use Docker to make static binaries that will work on dom0's old Fedora 25
docker:
	docker build -t test-mirage .
	docker run --rm -i test-mirage sh -c 'tar cf - _build/default/*.exe' | tar xf -

local:
	dune build @install
