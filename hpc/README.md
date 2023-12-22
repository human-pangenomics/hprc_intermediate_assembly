# Running HPRC Assemblies On HPC Environment

## Create TOIL Input JSON (launch_from_table.py)

This script takes in two data files and a workflow name and creates an input json file for launching a workflow with TOIL
```
python3 ./launch_from_table.py \
     --data_table sample_data_table.csv \
     --field_mapping input_mapping.csv \
     --workflow_name yak
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


## Read TOIL output JSONs and write updated data table (update_table_with_outputs.py)

This script takes in a data file, an output name, and the location of a workflow's output jsons in order to update the data file with the worklfow's outputs. This script is useful to update a data table with workflow outputs so they can be used as inputs into your next workflow.

## Call with 
```
python3 update_table_with_outputs.py \
     --input_data_table test.csv \
     --output_data_table test_updated.csv \
     --json_location '{sample_id}_hifiasm_output.json' \
     --field_mapping mapping.csv (optional)
```

### Inputs
* input_data_table (CSV file with header. First column must be sample_id): File that contains data locations for each sample. This is probably what you used to launch the workflow.
* output_data_table (String): the name of the input_data_table to write. Will be the input_data_table with columns added for outputs that the workflow wrote.
* json_location (String): Location of the output json that the workflow wrote. Note that it is expected that the output json is under a directory with the name {sample_id}.
* field_mapping (CSV file with header, optional): file that maps json keys (outputs from workflow) to column names in the output csv file.
	* json_key: The name for the json row (not including the workflow name)
	* output_name: The name of the column to write in the row.

### Note on optional field mapping file:

If none is provided all json keys are added to output CSV. If one is provided, keys in the json are looked up and the output CSV has a column with the name specified for that key. If no key mapping is found then the key is not written to the output (useful for workflows with a lot of outputs.)

------------------ 