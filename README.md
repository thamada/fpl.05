# PGR: a software package for reconfigurable super-computing

- [paper](https://ieeexplore.ieee.org/document/1515749)
- [pdf](./Final/fpl05.pdf)


## Abstruct

In this paper, we describe a methodology for implementing FPGA-based accelerator (FBA) from a high-level specification language. We have constructed a software package specially tuned for accelerating particle-based scientific computations with an FBA. Our software generates (a) a suitable configuration for the FPGA, (b) the C source code for interfacing with the FBA, and (c) a software emulator. The FPGA configuration is build by combining components from a library of parametrized arithmetic modules; these modules implement fixed-point, floating-point and logarithmic number system with flexible bitwidth and pipeline stages. To make certain our methodology is effective, we have applied our methodology to acceleration of astrophysical N-body application with two types of platforms. One is our PROGRAPE-3 with four XC2VP70-5 FPGAs and another is a minimum composition of CRAY-XD1 with one XC2VP50-7 FPGA. As the result, we have achieved peak performance of 324 Gflops with PROGRAPE-3 and 45 Gflops with the minimum CRAY-XD1, sustained performance of 236 Gflops with PROGRAPE-3 and 34 Gflops with the CRAY-XD1.


## Citation

```
T. Hamada and N. Nakasato, "PGR: a software package for reconfigurable super-computing," International Conference on Field Programmable Logic and Applications, 2005., Tampere, Finland, 2005, pp. 366-373, doi: 10.1109/FPL.2005.1515749. keywords: {Software packages;Field programmable gate arrays;Acceleration;Particle accelerators;Specification languages;Software libraries;Fixed-point arithmetic;Floating-point arithmetic;Pipelines;Application software},
```


```:bibtex
@INPROCEEDINGS{1515749,
  author={Hamada, T. and Nakasato, N.},
  booktitle={International Conference on Field Programmable Logic and Applications, 2005.}, 
  title={PGR: a software package for reconfigurable super-computing}, 
  year={2005},
  volume={},
  number={},
  pages={366-373},
  keywords={Software packages;Field programmable gate arrays;Acceleration;Particle accelerators;Specification languages;Software libraries;Fixed-point arithmetic;Floating-point arithmetic;Pipelines;Application software},
  doi={10.1109/FPL.2005.1515749}}
```


