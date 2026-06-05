### Working with the make commands

User can control the process of the project through an universal Makefile ecosystem. Here we discuss about these make commands. 

Note: Make sure before issuing the following commands (main vivado project control commands), the IPs are already built into the ips/ folder. 
Because, the **design-bd-src.tcl**  uses their path to instantiate them into the block design of the project.


  * The following command launches the vivado tool in batch mode and executes the "run-vivado-prj.tcl file which, in turn creates a vivado project and sets the target platform to the specified BOARD and DESIGN. In the run-vivado-prj.tcl, it also includes `tcls/bd/<BOARD>/<DESIGN>/design-bd-src.tcl`, to generate the block design (\*.bd) file. If your vivado project is already created, the terminal prints the message, and this is discarded. 


```
  make vivado BOARD=m1p DESIGN=system
```

  * If you already have created the viado project locally, during the developement of the project, you can update 
  the board/design-specific **design-bd-src.tcl** (regenerate), by issuing the following command. The following command will regenerate `tcls/bd/<BOARD>/<DESIGN>/design-bd-src.tcl` based on the current block design located in the generated Vivado project. Remember if you do not issue this command, after pushing your repository, your updates applied on the block design previously will not be visible for the remote repository. 

```
  make update_tcl BOARD=m1p DESIGN=system
```
 
 
  * Once you have your design created, or updated, you must generate the output products of included IPs. For this purpose, we issue the following command:


```
  make ip_ooc OOC_JOBS=16                
```


  * Once you have generated all the IPs, we can issue following command to generate the bitstream. The reports are created into the folder named **report**.

```
  make synth
  make impl               
```

<!--   * Cleaning the environment: CAUTIOUS! by issuing the following command your vivado project folder entirely will be deleted and only source codes including the tcl files, and the old block design (bd_old), and the actual block design, will remain into the src/* folder. The tracking to the block design is not done through this block designs but only through the **design-bd-src.tcl**. If you forget to issue the **make update_tcl**, and then clean the environment, you do not loose your modifications on the block design file becasue it is put into a separate folder which is the goal of the clean operation. 

```
  make clean
``` 
 -->


Here is the project directory structure tree:

    
      PROJECT_NAME
          ├── .git
          ├── .gitignore
          ├── README.md
          ├── Makefile                             # Main Makefile of the project  
          ├── tcls/                                # tcl scripts to control the flow of the project
          │     │
          │     ├── add-rtl-sources.tcl
          │     ├── bd/
          │     │   ├── m1/
          │     │   │   └── system/
          │     │   │       └── design-bd-src.tcl
          │     │   └── m1p/
          │     │       └── system/
          │     │           └── design-bd-src.tcl
          │     ├── gen-bd-tcl.tcl
          │     ├── run-impl.tcl 
          │     ├── run-ooc.tcl 
          │     ├── run-synth.tcl 
          │     ├── run-vivado-prj.tcl 
          │     └── settings.tcl 
          │
          │
          │
          ├── ips/                     
          │   ├── env_variables.sh                 # Bash environment variables used for the "ips" generation. 
          │   │                                    # If we run "make" into the sub-directories of the  
          │   │                                    # ips (not main "make" in ips/Makefile), we must source this file.                            
          │   │                                                    
          │   │                                                    
          │   ├── Makefile                         # Main Makefile of the "ips" generation.
          │   │
          │   ├── hls-ips                          # The HLS-based generated IPs. 
          │   │    ├── common.mk                   # Common commands that are used to make each IPs including the 
          │   │    │                               # "vivado_hls" run in batch mode.
          │   │    ├── include/                    # All the headers used in the "hls-ips" sub-directories in each 
          │   │    │                               # *.cpp files.
          │   │    ├── hls_*                       # All of the directories of each IP starts with a "hls_" prefix.
          │   │    │    ├── Makefile               # The sub-directories Makefile, which locally also can be executed
          │   │    │    │                          # (before sourcing the env_variables.sh).
          │   │    │    ├── src/                   # C++ source files for each HLS IPs.
          │   │    │    │     ├── 2016.3           # Vivado HLS 2016.3 compatible C++ source code.
          │   │    │    │     └── 2020.2           # Vivado HLS 2020.2 compatible C++ source code.
          │   │    │    │
          │   │    │    └── tcl/                   # Tcl scripts to control the flow of the Vivado and 
          │   │    │          │                    # Vivado HLS IP synthesis
          │   │    │          ├── run-hls.tcl      # Tcl script which manages the vivado_hls tool.       
          │   │    │          └── run-vivado.tcl   # Tcl script which manages the vivado tool. This is not used in generating this IP. 
          │   │    │
          │   │    └── ...     
          │   │
          │   ├── vhd-ips                          # The HDL-based generated IPs (can be any hdl language).
          │   │                                    # The user should consider the IPs that are wrapped as an IP-XACT here.
          │   │                                    
          │   └── work-fpga                        # Untracked generated IPs in vhdl form.                                            
          │                                       
          │   
          ├── srcs/                                # Possible source files: *.v, *.hdl, *.sv, *.bd backups, and UI layout files
          │    │                                   # are stored here.
          │    │     
          │    ├──  rtl/                           # board/design-specific RTL module-reference sources
          │    │    ├── common/
          │    │    ├── m1/
          │    │    │   └── system/
          │    │    └── m1p/
          │    │        └── system/
          │    │            └── include/
          │    │
          │    ├──  bd_old/                        # when issuing "make update_tcl", before updating the board/design-specific
          │    │    ├── m1/                        # "design-bd-src.tcl", the current bd file is copied here.
          │    │    │   └── system/
          │    │    └── m1p/
          │    │        └── system/
          │    │
          │    └──  stored_ui/                     # saved/ordered *.ui files which define the layout of the block design.
          │         ├── m1/
          │         │   └── system/
          │         └── m1p/
          │             └── system/
          │     
          ├── constraints/                         # Only *.xdc files under constraints/<BOARD>/ are added.
          │     ├── m1/
          │     │   └── system/
          │     └── m1p/
          │         └── system/
          │     
          |
          └── vivado-prj/                          # Untracked generated files, but not considered as part of clean.
              ├── board1-vivado.xpr
              ├── board1-vivado.cache/
              ├── board1-vivado.hw/
              ├── board1-vivado.sim/
              ├── board1-vivado.srcs/
              │    ├── sources_1/
              │    │    ├── bd/                                         # BDs are regenerated from script
              │    │    │    ├── bd/hdl/system_wrapper.{v,vhd}     # BD wrappers are also regenerated
              │    │    │    └── ...
              │    │    └── ...
              │    └── ...
              └── ...


