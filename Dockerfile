FROM ocurrent/opam:alpine
WORKDIR /src
COPY --chown=opam test-mirage.opam /src/test-mirage.opam
RUN opam pin -n test-mirage .
RUN opam depext test-mirage
RUN opam install --deps-only test-mirage
RUN sudo chown opam .
COPY --chown=opam . .
RUN echo "(lang dune 1.11)" > dune-workspace
RUN echo "(env (_ (flags -cclib -static)))" >> dune-workspace
RUN opam exec -- dune build --profile=release @install
