{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";   # adjust if necessary
      pkgs = import nixpkgs {
        inherit system;

        # --- key change: turn CUDA on globally ---
        config = {
          allowUnfree  = true;
          cudaSupport  = true;         # makes “torch” a CUDA build
          # Optionally trim the build to your GPU:
          # cudaCapabilities = [ "8.6" ];
        };
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        /*-----------------------------------------
          Packages available in the development shell
        ------------------------------------------*/
        packages = with pkgs; [
          (python3.withPackages (ps: with ps; [
            ipython
            ipykernel
            jupyter
            numpy
            pandas
            matplotlib
            seaborn
            scikit-learn
            torch        # already CUDA-enabled
            torchvision
          ]))

          # Keep these only if you plan to compile custom CUDA extensions
          # cudatoolkit
          # cudaPackages.cudnn

          # CUDA 12.x still wants GCC ≤ 13 for nvcc;
          # override the host compiler accordingly
          gcc13
        ];

        /*-----------------------------------------
          Extra environment wiring (mostly unchanged)
        ------------------------------------------*/
        shellHook = ''
          # Use GCC 13 so nvcc picks a compatible compiler
          export CC=${pkgs.gcc13}/bin/gcc
          export CXX=${pkgs.gcc13}/bin/g++

          # If you build custom CUDA code, make sure CUDA_PATH is set
          export CUDA_PATH=${pkgs.cudatoolkit}

          # Extend dynamic linker path for OpenGL & CUDA (needed only when
          # compiling your own kernels)
          export LD_LIBRARY_PATH=${
            pkgs.lib.makeLibraryPath [
              "/run/opengl-driver"   # libGL.so from the running driver
              pkgs.cudatoolkit
              pkgs.cudaPackages.cudnn
            ]
          }:$LD_LIBRARY_PATH
        '';
      };
    };
}
