(lang dune 2.3)

(formatting disabled)
(generate_opam_files true)

(source (github talex5/qubes-test-mirage))
(authors "talex5@gmail.com")
(maintainers "talex5@gmail.com")

(package
 (name test-mirage)
 (synopsis "Test Mirage unikernels easily on QubesOS")
 (depends lwt (ocaml (>= 4.08))))
