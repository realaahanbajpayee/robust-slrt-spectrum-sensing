# Robust SLRT Spectrum Sensing

MATLAB implementation of standard and robust spectrum-sensing detectors under Gaussian and non-Gaussian noise.

This project evaluates six detector variants:
- Energy Detection (ED) and Robust ED (RED)
- SLRT Detector 1 (SLRTD1) and Robust SLRTD1
- SLRT Detector 2 (SLRTD2) and Robust SLRTD2

The simulations cover Gaussian, Laplacian, impulsive, and symmetric alpha-stable noise. Robust variants use median-based location and Median Absolute Deviation (MAD) scale estimation.

## Run

Open the project folder in MATLAB and run:

```matlab
main
```

The script runs the Monte Carlo detection-probability sweeps, calibrates detector thresholds to the target false-alarm probability, profiles execution time, and generates ROC plots.

## Results

The `results` folder contains the replicated ROC figure, saved MATLAB workspace, and summary of the measured detection and runtime results.

## Reference

B. Bhavana, S. L. Sabat, and T. Panigrahi, “A Robust Simultaneous Likelihood Ratio Test Detector for Wideband Spectrum Sensing Under Non-Gaussian Noise,” *IEEE Transactions on Cognitive Communications and Networking*, vol. 12, pp. 370–381, 2026.

[https://doi.org/10.1109/TCCN.2025.3559550](https://doi.org/10.1109/TCCN.2025.3559550)
