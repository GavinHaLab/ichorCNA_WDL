import csv
import json
import sys

### converts each row of input csv file into a dictionary
def convert_csv_to_dictionary(input_csv):
    data = []
    with open(input_csv, 'r') as file:
        csv_reader = csv.DictReader(file)
        for row in csv_reader:
            data.append(row)
    return data

###  create a json data
def output_json_file(input_csv, output_json, json_name, **fixed_paramteres):
    data = convert_csv_to_dictionary(input_csv)
    # add fixed parameters
    json_data = {
        json_name: data,
        **fixed_paramteres
    }
    # output json data 
    with open(output_json, 'w') as file:
        json.dump(json_data, file, indent=4)

# fixed paramters
json_name = 'ichorCNA.batchSamples'
fixed_paramteres = {"ichorCNA.exons": None, 
                    "ichorCNA.binSize": "1000kb",
                    "ichorCNA.binSizeNumeric": 1000000,
                    "ichorCNA.qual": 20,
                    "ichorCNA.normal": "c(0.5,0.6,0.7,0.8,0.9,0.95)",
                    "ichorCNA.ploidy": "c(2,3)",
                    "ichorCNA.estimateNormal": "TRUE",
                    "ichorCNA.estimatePloidy": "TRUE",
                    "ichorCNA.estimateClonality": "TRUE",
                    "ichorCNA.scStates": "c(1,3)",
                    "ichorCNA.maxCN": 5,
                    "ichorCNA.scPenalty": 1,
                    "ichorCNA.includeHOMD": "FALSE",
                    "ichorCNA.plotFileType": "pdf",
                    "ichorCNA.plotYlim": "c(-2,4)",
                    "ichorCNA.likModel": "t",
                    "ichorCNA.minMapScore": 0.75,
                    "ichorCNA.maxFracGenomeSubclone": 0.5,
                    "ichorCNA.maxFracCNASubclone": 0.7,
                    "ichorCNA.normal2IgnoreSC": 0.90,
                    "ichorCNA.txnE": 0.9999,
                    "ichorCNA.txnStrength": 10000,
                    "ichorCNA.fracReadsInChrYForMale": 0.002
                    }


def main(input_csv, output_json):
    output_json_file(input_csv, output_json, json_name, **fixed_paramteres)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 script.py input_csv output_json")
        sys.exit(1)

    input_csv = sys.argv[1]
    output_json = sys.argv[2]
    main(input_csv, output_json)
