# Running HPRC Assemblies On HPC Environment

## Create TOIL Input JSON (launch_from_table.py)

This script takes in two data files and a workflow name and creates an input json file for launching a workflow with TOIL
```
python3 ./launch_from_table.py \
     --data_table sample_data_table.csv \
     --field_mapping input_mapping_hifiasm.csv \
     --workflow_name hifiasm
```

### Inputs
* field_mapping (CSV file with header): file that maps either values or columns to lookup in the data_table file to inputs expected in the workflow.
	* input: The name for the json row
	* type: The type of value (array/scalar) that the workflow requires.
	* value: The value to write in the row. Can be a value that is hard coded, or can take `$input.column_name` where `column_name` is a column that can be found in the header of the data_table file.
* data_table (CSV file with header. First column must be sample_id): File that contains data locations for each sample. 
* workflow_name (String): workflow that you are running (only used for nameing the json file)

### Outputs

* `{sample_id}_{workflow_name}.json`


------------------ 