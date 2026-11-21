# Captured Benchmark Summary

This file records the values printed by the supplied `main.m` run. The tables are also included in the root README.

## Table II — Target SNR at `Pd >= 0.90`

| Detector | GN (dB) | LN (dB) | IN (dB) | SαSN GSNR (dB) |
|---|---:|---:|---:|---:|
| ED (standard) | -7.2 | -5.1 | -3.3 | NaN |
| Robust ED (RED) | -3.8 | -2.4 | -2.1 | NaN |
| SLRTD1 (standard) | -6.3 | -4.9 | -3.1 | NaN |
| Robust SLRTD1 | -2.6 | -6.2 | -5.3 | +0.0 |
| SLRTD2 (standard) | -4.5 | -2.9 | -1.0 | NaN |
| Robust SLRTD2 | -2.3 | -5.9 | -5.0 | +0.4 |

## Table III — Mean execution runtime (µs)

| Detector | GN | LN | IN | SαSN |
|---|---:|---:|---:|---:|
| ED (standard) | 9.8 | 8.8 | 8.2 | 8.5 |
| Robust ED (RED) | 51.4 | 49.7 | 49.1 | 49.9 |
| SLRTD1 (standard) | 15.7 | 12.5 | 12.6 | 12.2 |
| Robust SLRTD1 | 83.3 | 80.3 | 77.2 | 81.1 |
| SLRTD2 (standard) | 54.1 | 19.0 | 19.9 | 20.1 |
| Robust SLRTD2 | 62.8 | 66.2 | 67.1 | 64.2 |

`NaN` means no threshold crossing was found in the tested SNR/GSNR range. Runtime values are environment-dependent.
