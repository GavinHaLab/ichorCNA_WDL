# ichorCNA-wdl
WDL for https://github.com/GavinHaLab/ichorCNA. \
A revised version of [this WDL](https://github.com/GavinHaLab/wdl-repo/tree/main/ichorCNA/old/) so that it outputs plots.
[Here is info on a snakemake version](https://github.com/broadinstitute/ichorCNA/wiki/SnakeMake-pipeline-for-ichorCNA) for comparison. 

The ichorCNA.wdl workflow has two tasks:
- `read_counter`
- `run_ichorCNA`

The wdl calls a `scatter` and calls both tasks for each sample in `batchSamples`.

The workflow outputs 8 files:
- `~{sampleName}.bin~{binSize}.wig`
- `~{sampleId}.correctedDepth.txt`
- `~{sampleId}.cna.seg`
- `~{sampleId}.params.txt`
- `~{sampleId}.seg.txt`
- `~{sampleId}.seg`
- `~{sampleId}.RData`
- `~{sampleId}.plots.tar.gz`

## ichorCNA Wiki Page
For more info on the ichorCNA tool, visit the [Github Wiki page for ichorCNA](https://github.com/broadinstitute/ichorCNA/wiki) by the BROAD Institute.

## Configuration
### ichorCNA.wdl file
`taskDocker`: By default fredhutch/ichorcna:v0.5.0 is set, and doesn't need to be changed unless you wish to.\
`taskCPU`: CPU variable for run_ichorCNA. May have to edit `read_counter` CPU in its runtime section.\
`memory`: This may have to be edited in both `read_counter` and `run_ichorCNA` in their runtime sections.

### inputs.json file

In batchSamples:
All sample information including any paired normal bams, or a normal panel, and genome build information for individual bams

"`sampleName`"  
"`sex`"- use "None" if both male and female are in sample  
"`tumorBam`"- Path to tumor bam file.  
"`tumorBai`"- Path to tumor bam.bai file.  
"`normalBam`"- Path to normal bam file. Can be null  
"`normalBai`"- Path to normal bam.bai file. Can be null  
"`normalPanel`"- Median corrected depth from panel of normals. Default: null.
"`genomeBuild`"- hg19 or hg38 only, capitalization matters  
"`genomeStyle`"- "NCBI" when hg19 or "UCSC" when hg38

Other inputs:
Workflow level params

"`ichorCNA.exons`"- Path to bed file containing exon regions. Default: "NULL"  
"`ichorCNA.binSize`"- "10kb" This must match binSizeNumeric  
"`ichorCNA.binSizeNumeric`"- 10000, but must match the other binSize  
"`ichorCNA.qual`"- Integer- i.e. 20  
"`ichorCNA.normal`"- Initial normal contamination; can be more than one value if additional normal initializations are desired. Default: "0.5"  
"`ichorCNA.ploidy`"- Initial tumour ploidy; can be more than one value if additional ploidy initializations are desired. Default: "2"  
"`ichorCNA.estimateNormal`"- Estimate normal. These need to be quoted strings in all caps instead of Boolean b/c of R. Default: "TRUE"  
"`ichorCNA.estimatePloidy`"- Estimate tumour ploidy. Default: "TRUE"  
"`ichorCNA.estimateClonality`"- Estimate clonality. Default: "TRUE"  
"`ichorCNA.scStates`"- Subclonal states to consider. Default: "NULL"  
"`ichorCNA.maxCN`"- Total clonal CN states. Default: "7"  
"`ichorCNA.scPenalty`"- penalize subclonal events - n-fold multiplier; n=1 for no penalty  
"`ichorCNA.includeHOMD`"- If FALSE, then exclude HOMD state. Useful when using large bins (e.g. 1Mb). Default: "FALSE"  
"`ichorCNA.plotFileType`"- File format for output plots. pdf or png. Default: "pdf"  
"`ichorCNA.plotYlim`"- ylim to use for chromosome plots. Default: "c(-2,2)"  
"`ichorCNA.likModel`"- Default: "t". if multisample, use "gauss"  
"`ichorCNA.minMapScore`"- control segmentation - higher (e.g. 0.9999999) leads to higher specificity and fewer segments  
"`ichorCNA.maxFracGenomeSubclone`"- Exclude solutions with subclonal genome fraction greater than this value. Default: "0.5"  
"`ichorCNA.maxFracCNASubclone`"- Exclude solutions with fraction of subclonal events greater than this value. Default: "0.7"  
"`ichorCNA.normal2IgnoreSC`"- Ignore subclonal analysis when initial normal setting >= this value  
"`ichorCNA.txnE`"- Self-transition probability. Increase to decrease number of segments. Lower (e.g. 0.99) leads to higher sensitivity and more segments. Default: "0.9999999". Higher (e.g. 10000000) leads to higher specificity and fewer segments and lower (e.g. 100) leads to higher sensitivity and more segments  
"`ichorCNA.txnStrength`"- Transition pseudo-counts. Exponent should be the same as the number of decimal places of txnE. Default: "1e+07"  
"`ichorCNA.fracReadsInChrYForMale`"- Threshold for fraction of reads in chrY to assign as male. Default: "0.001"  


## Outputs
A complete list of outputs can be found in [this Github wiki page](https://github.com/broadinstitute/ichorCNA/wiki/Output) along with parameter info.

## Instructions
[For FH users here](#instructions-for-fh-users)

Else:
You can run it if your workplace already has a Cromwell server configured or by other WDL execution tools.

This is just a rough explanation of what I've tested this with and how you can do it yourself, from a beginner's perspective.
You can run this on your own if you have [cromwell installed](https://github.com/broadinstitute/cromwell/releases/tag/85) and want to use the `run` or `server` mode.

### Run mode
To do this, enter this into your terminal:

    java -jar cromwell-XX.jar run ichorCNA.wdl -i inputs.json -o options.json

with `XX` being the version of cromwell you have. Make sure all of your files (WDL, input, options) are in the same folder as the cromwell .jar file.

### Server mode
[Here is a tutorial on how to run Cromwell's server mode](https://cromwell.readthedocs.io/en/stable/tutorials/ServerMode/). Skip the Five Minute Introduction if you've already downloaded Cromwell and familiar with it.

## Instructions for FH users
### Running via shiny app

Open the [shiny app](https://cromwellapp.fredhutch.org/) and connect to your cromwell server. Under "Submit a Workflow", upload the WDL and inputs.json. If you wanted to configure the workflow, [take a workflow options file](https://github.com/GavinHaLab/WDL_Pipelines/tree/main/workflow-options) and upload it as well.


### Running via command line
Log into your chosen node and set the current directory to where your ichorCNA.wdl, inputs.json, and your optional workflow_options.json files are stored. Load the modules necessary:

`module load java`

`module load cromwell`

#### To execute the WDL, do the following:

`python3 create_input_json.py input_test_ichorCNA.csv inputs.json`

This command creates a json file with all the samples present in the input _'input_test_ichorCNA.csv'_. Please check the format of the csv file.
Next, pass the _'inputs.json'_ file to the following command.

`java -jar $EBROOTCROMWELL/cromwell.jar run ichorCNA.wdl -i inputs.json`

To configure the workflow, add `--options workflow_options.json` to the line. [More on workflow options](https://github.com/GavinHaLab/WDL_Pipelines/tree/main/workflow-options).
