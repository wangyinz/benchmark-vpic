# benchmark-vpic

This repository containsthe files needed to build the VPIC (Vector Particle-In-Cell) for SPP benchmark.

## Deployment

The `build.sh` will automatically create a new directory and perform an out-of-tree build there. It can also automatically create and submit a user specified test. Users can specify the version of compiler, MPI, and architecture related flag for the build. For the usage of the script, please run:

```
./build.sh -h
```

## Notes

The `input_files` directory contains the standard test problems from the SPP benchmark. The number in the filename indicats how many tasks should be requested for the test.  They are from multiplying topology_x, topology_y and topology_z. Note that all the topology should be evenly devided by their corresponding nx, ny, nz.

nx,ny,nz and Lz,Ly,Lz determine the size (complexity) of the problem. Changing topology to fit the same problem into different number of nodes.

There are two problems (small test and large test) from the original SPP benchmarks included here:

```
  double Lx            = 300*di; 
  double Ly            = 300*di; 
  double Lz            = 50*di; 

  double nx = 1200;
  double ny = 1200;
  double nz = 200;
```

and

```
  double Lx            = 40.0*di;
  double Ly            = 40.0*di;
  double Lz            = 15.0*di;

  double nx = 1536;
  double ny = 1536;
  double nz = 1536;
```

Another problem modified from the small test is also included to make it fit onto one node. Note that nx,ny,nz are set to some special numbers so that some chips with an uncommon core count (e.g. knl) can be better utilized.

```
  double nppc          = 70;

  double Lx            = 420*di;
  double Ly            = 340*di;
  double Lz            = 50*di;

  double topology_x = 2;  
  double topology_y = 2;
  double topology_z = 2;  

  double nx = 420;
  double ny = 340;
  double nz = 50;
```
