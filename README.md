### Working with the make commands

This repository creates Vivado projects from a board/design-specific **Vivado Project Tcl** file.
The previous block-design Tcl flow has been removed. `make vivado` reads a project restoration Tcl from:

```text
tcls/project/<BOARD>/<DESIGN>/project-src.tcl
```

For example:

```text
tcls/project/m1p/system/project-src.tcl
```

The project Tcl may be a Vivado-generated `write_project_tcl`/project restoration script. During
`make vivado`, the script is sourced directly with `::origin_dir_loc` set to the repository root,
so paths emitted by `make update_tcl` remain reproducible without an intermediate normalized copy.

### Source and constraint layout

Even though the project is created from Project Tcl, the repository-managed source and constraint
directories are still used and are re-attached after the project Tcl creates the Vivado project.

Place project files in these locations:

```text
srcs/rtl/common
srcs/rtl/<BOARD>/common
srcs/rtl/<BOARD>/<DESIGN>
srcs/rtl/<DESIGN>

srcs/xci/common
srcs/xci/<BOARD>/common
srcs/xci/<BOARD>/<DESIGN>
srcs/xci/<DESIGN>

srcs/bd/<BOARD>/<DESIGN>
srcs/dcp/<BOARD>/<DESIGN>

constraints/<BOARD>/<DESIGN>
```

For the default design, typical locations are:

```text
srcs/rtl/m1p/system/
srcs/xci/m1p/system/fir_2dec/
srcs/bd/m1p/system/system.bd
srcs/dcp/m1p/system/system_wrapper.dcp
constraints/m1p/system/pins.xdc
```

The DCP file is optional. If `srcs/dcp/<BOARD>/<DESIGN>/system_wrapper.dcp` is not present, the
Project Tcl should skip the incremental checkpoint setting instead of failing project creation.

### `make vivado`

The following command creates the Vivado project for the selected board and design:

```bash
make vivado BOARD=m1p DESIGN=system
```

The flow is:

1. Build custom IPs under `ips/`.
2. Read `tcls/project/<BOARD>/<DESIGN>/project-src.tcl`.
3. Set the Tcl working directory to `vivado-prj/<BOARD>/<DESIGN>`.
4. Set `::origin_dir_loc` to the repository root and `::user_project_name` to the make-selected
   Vivado project name.
5. Source the Project Tcl directly to create the Vivado project.
6. Re-attach repository sources from `srcs/rtl` and standalone XCI files from `srcs/xci`.
7. Re-attach XDC files from `constraints/<BOARD>` recursively.
8. Refresh the BD wrapper and set `<DESIGN>_wrapper` as the top module.

The generated Vivado project is located at:

```text
vivado-prj/<BOARD>/<DESIGN>/<BOARD>-<DESIGN>-vivado/<BOARD>-<DESIGN>-vivado.xpr
```

For example:

```text
vivado-prj/m1p/system/m1p-system-vivado/m1p-system-vivado.xpr
```

### `make update_tcl`

If you have modified the generated Vivado project locally and want to update the source-controlled
Project Tcl, run:

```bash
make update_tcl BOARD=m1p DESIGN=system
```

This exports the current Vivado project with `write_project_tcl` into:

```text
tcls/project/<BOARD>/<DESIGN>/project-src.tcl
```

The export script uses the following Project Tcl options to keep the repository
layout reproducible:

```text
-use_bd_files
-no_copy_sources
-paths_relative_to <repository root>
```

When supported by the installed Vivado version, it also tries `-all_properties`.
If that option is not accepted, the script retries while keeping the required
`-use_bd_files`, `-no_copy_sources`, and `-paths_relative_to` options.

The source-controlled BD location is:

```text
srcs/bd/<BOARD>/<DESIGN>/<DESIGN>.bd
```

`make update_tcl` saves the currently opened/generated BD and synchronizes it to
that location before exporting the project Tcl.

If a block design exists, the current `.bd` is saved first and a copy is also preserved under:

```text
srcs/bd_old/<BOARD>/<DESIGN>/
```

Stored BD UI files are copied to:

```text
srcs/stored_ui/<BOARD>/<DESIGN>/
```

### OOC, synthesis, implementation, and XSA

Once the project has been created, the existing make targets continue to operate on the generated
Vivado project:

```bash
make ip_ooc BOARD=m1p DESIGN=system
make synth  BOARD=m1p DESIGN=system
make impl   BOARD=m1p DESIGN=system
make xsa    BOARD=m1p DESIGN=system
```

The full flow is:

```bash
make all BOARD=m1p DESIGN=system
```

`make all` runs:

```text
synth -> impl -> xsa
```

The `synth` target first runs `ip_ooc`, so the effective hardware flow is:

```text
ip_ooc -> synth_1 -> impl_1 -> write_bitstream -> write_hw_platform
```

### Project directory structure

```text
PROJECT_NAME
├── Makefile
├── README.md
├── tcls/
│   ├── add-rtl-sources.tcl
│   ├── add-xci-sources.tcl
│   ├── gen-project-tcl.tcl
│   ├── run-impl.tcl
│   ├── run-ooc.tcl
│   ├── run-synth.tcl
│   ├── run-vivado-prj.tcl
│   ├── run-xsa.tcl
│   ├── settings.tcl
│   └── project/
│       └── m1p/
│           └── system/
│               └── project-src.tcl
├── ips/
│   ├── Makefile
│   ├── env_variables.sh
│   ├── hls-ips/
│   └── vhd-ips/
├── srcs/
│   ├── rtl/
│   │   ├── common/
│   │   └── m1p/
│   │       └── system/
│   ├── xci/
│   │   └── m1p/
│   │       └── system/
│   ├── bd/
│   │   └── m1p/
│   │       └── system/
│   ├── dcp/
│   │   └── m1p/
│   │       └── system/
│   ├── bd_old/
│   ├── libs/
│   └── stored_ui/
├── constraints/
│   └── m1p/
│       └── system/
└── vivado-prj/
    └── m1p/
        └── system/
            └── m1p-system-vivado/
                ├── m1p-system-vivado.gen/
                ├── m1p-system-vivado.srcs/
                └── m1p-system-vivado.xpr
```
