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

    libs = list(binary.libraries)
    changed = False

    for lib in libs:
        if lib == old_path:
            print(f"  Replacing dependency: {old_path} -> {new_path}")
            binary.remove(lief.MachO.LoadCommand.TYPE.LOAD_DYLIB, old_path)
            binary.add_library(new_path)
            changed = True
            break

    if not changed:
        print(f"  No matching dependency found in {dylib_path}")

    binary.write(str(dylib_path))
