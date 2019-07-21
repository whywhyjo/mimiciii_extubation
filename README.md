UNDER CONSTRUCTION
==============

# Prediction the extubation failure
## Objective
We are trying to devleop the precition model for the extubation failure. 
To this end, we first construct a dataset from the original mimic-iii database.
This git includes the procedures to define the population and extract variable related to them.
For the furture work, we implement the prediction model based on machine (deep) learing algorithms. 

## Population & variables

### Population definition


### Variable list
Look at the [item_ids_dict](./csv/item_ids_dict.csv)
- There are about 70 variables related to our population with thier IDs defined MIMIC-iii clinical database.

### Contributors
All related to the medical part are defined by our medical team.
- Young-Jae Cho, MD at Pulmonary and Critical Care, Seoul Nation University Bundang Hospital, South Korea 
- Hyung Sook Lee at, ?? Seoul National University
- Jong Hwan Jang, Asan 

## Requirements
We provide Jupyter Notebook codes, and SQLs based on Postgresql.
- The MIMIC-iii clinical database is already builed on Postgresql [mimic_git](https://github.com/MIT-LCP/mimic-code/blob/master/Makefile.md).
- The code requires Python 3.7 or later. 
- The additional required models for Python is numpy, pandas, and psycopg2.

## Usage
- First, download our git (git clone https://github.com/whywhyjo/mimiciii_extubation).
- Second, excute [population_definition.ipynb](./population_definition.ipynb) on Jupyter Notebook to define the population.
    - This node print out defining population.
- Then, excute [variable_extraction.ipynb](./variable_extraction.ipynb) to extract variables w.r.t. the population.
