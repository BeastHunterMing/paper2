# Optimization Operational Framework of Virtual Power Plant Based on Dynamic Information Entropy Assessment Approach

This repository contains the MATLAB implementation of an optimization operational framework for virtual power plants (VPP) using a dynamic information entropy assessment approach. The code includes the proposed method and several comparison methods for performance evaluation.

## Main Files

- **`main_mymethod.m`** - Main method from this paper:
  - Bi-objective function
  - Information entropy evaluation
  - Hydrogen storage capacity coefficient
  - Uses randomly generated data

- **`main_mymethod_fix.m`** - Same method with fixed generated data for comparison

- **`main_2obj_noEnp_noStr.m`** - Comparison method:
  - Bi-objective function
  - No information entropy evaluation
  - No hydrogen storage capacity coefficient

- **`main_1obj_noEnp_nostr2.m`** - Comparison method:
  - Bi-objective function
  - Information entropy evaluation (only parameter adjustment, no weight regulation)

- **`main_1obj_noEnp_str1.m`** - Comparison method:
  - Single-objective function (economic)
  - No information entropy evaluation
  - No system parameter adjustment

- **`result_compare.m`** - Results comparison of all methods

## Core Functions

### Optimization Functions
- **`DAY_ope1.m`** - Proposed method: bi-objective with parameter adjustment and entropy evaluation
- **`DAY_ope2.m`** - Comparison: bi-objective without entropy evaluation
- **`DAY_ope3.m`** - Comparison: bi-objective with entropy evaluation (parameter adjustment only)
- **`DAY_ope4_2.m`** - Comparison: single-objective (economic) with entropy evaluation
- **`DAY_ope5.m`** - Comparison: single-objective (economic) without entropy evaluation

### Data Processing
- **`data_generator_func.m`** - Data generation using alpha-stable distribution for PV/wind uncertainty
- **`LOAD_ehH.m`** - Loads four types of load data
- **`get_data.m`** - Converts HaoCurve .mat data to usable format
- **`CalculateProbabilityDensity.m`** - Calculates information entropy

### Optimization Stages
#### Day-Ahead Stage
- **`onestage_Cost1.m`** - Optimizes Cost1 (economic indicator: electricity/gas purchase)
- **`onestage_Cost2.m`** - Optimizes Cost2 (hydrogen storage tank capacity)
- **`onestage_Cost3.m`** - Weighted optimization of Cost1 and Cost2

#### Real-Time Stage
- **`twostage.m`** - Real-time stage objective function

### Utility Functions
- **`WCM.m`** - Weight calculation method for objective functions
- **`compute_score.m`** - Modified weighted score calculation

## Data Files
- **`data_generation_20250727.mat`** - Pre-generated data for method comparison (created by `data_generator_func`)

## Usage
1. Run main files to execute different methods
2. Use `result_compare.m` to compare performance across methods
3. Modify parameters in respective functions for different scenarios

## Requirements
- MATLAB R2018b or later
- Optimization Toolbox
- Statistics and Machine Learning Toolbox

## Citation
If you use this code in your research, please cite our paper on "Optimization operational framework of virtual power plant based on dynamic information entropy assessment approach".

## License
This project is licensed for academic use only.
