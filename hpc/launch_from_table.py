import pandas as pd
import json
import argparse

## Call with 
# python3 launch_from_table.py \
#      --data_table test.csv \
#      --field_mapping mapping.csv \
#      --workflow_name yak

###############################################################################
##                               Parse Inputs                                ##
###############################################################################

parser = argparse.ArgumentParser()

parser.add_argument('--data_table', '-d', 
                    type=str, action='store', help='input csv with one row per sample and columns with data inputs.')
parser.add_argument('--field_mapping', '-f', 
                    type=str, action='store', help='mapping of columns from data_table to workflow json inputs')
parser.add_argument('--workflow_name', '-w', default='workflow', 
                    type=str, action='store', help='Workflow name to add to json file output')

args = parser.parse_args()

data_table      = args.data_table
field_mapping   = args.field_mapping
workflow_name   = args.workflow_name


###############################################################################
##                        Create Input JSON For Toil                         ##
###############################################################################

# Read the CSV file into a Pandas DataFrame
data_df     = pd.read_csv(data_table)
mapping_df  = pd.read_csv(field_mapping)

## Loop through each sample in data inputs...
for data_index, data_row in data_df.iterrows():

    ## get current sample ID
    sample_id = data_row[0]

    print(f'Creating json for {sample_id}')

    ## Initialize an empty dictionary to store the JSON data for sample
    sample_json_dict = {}
    
    ## Iterate through each row in the mapping file
    for mapping_index, mapping_row in mapping_df.iterrows():

        input_type  = mapping_row['type']
        input_value = mapping_row['value']

        # Check if the value is a reference to the data file
        if input_value.startswith('$input.'):
            
            # Get the corresponding data value from the data file
            data_column_name = input_value.split('$input.')[1]
            data_value = data_row[data_column_name]

        # no need to get from input data file, just use value in mapping file
        # this is used for values that are always the same (like reference files)
        else:
            data_value = input_value


        ## Check if the input type is 'array' and the data value is a string representation of a list
        ## Some WDL array inputs may be given as a single element in the data table. 
        ## Some may be given as an array with a nasty format such as "[""elementA"",elementB""]"
        ## We need to be able to hold both values as a list so the json writes the array correctly.
        if input_type == 'array' and isinstance(data_value, str):
            try:
                # Attempt to convert the string representation to a list
                data_value = json.loads(data_value.replace("'", "\""))

            except json.JSONDecodeError:
                # If conversion fails, treat it as a single-element list
                data_value = [data_value]

        ## Format scalar values so ints, floats, and bools are converted from str to correct type
        elif input_type == 'scalar':
            try:
                data_value = int(data_value)
            except ValueError:
                try:
                    data_value = float(data_value)
                except ValueError:
                    if data_value.lower() == 'true' or data_value.lower() == 'false':
                        data_value = data_value.lower() == 'true'
                    else:
                        data_value = data_value

        ## Set the value in the dictionary!
        sample_json_dict[mapping_row['input']] = data_value
        

    ## Write json file
    with open(f'{sample_id}_{workflow_name}.json', 'w') as json_file:
        json.dump(sample_json_dict, json_file, indent=2)



###############################################################################
##                                  DONE                                     ##
###############################################################################