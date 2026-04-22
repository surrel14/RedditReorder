import pathlib
import lief

output_dir = pathlib.Path("output")
dylibs = list(output_dir.glob("*.dylib"))

if not dylibs:
    raise SystemExit("No dylib found in output/")

old_path = "/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate"
new_path = "@executable_path/libsubstrate.dylib"

for dylib_path in dylibs:
    print(f"Patching {dylib_path}")
    binary = lief.parse(str(dylib_path))
    if binary is None:
        raise RuntimeError(f"Failed to parse {dylib_path}")

    changed = False

    for lib in list(binary.libraries):
        lib_name = lib.name
        if lib_name == old_path:
            print(f"  Replacing dependency: {old_path} -> {new_path}")

            # rimuove il vecchio load command
            binary.remove(lib)

            # aggiunge il nuovo
            binary.add_library(new_path)

            changed = True
            break

    if not changed:
        print(f"  No matching dependency found in {dylib_path}")

    binary.write(str(dylib_path))
