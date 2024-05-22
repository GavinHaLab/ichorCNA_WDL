version 1.0
struct sampleData {
  ## All sample information including any paired normal bams, or a normal panel, and genome build information for individual bams
  String sampleName 
  String sex 
  File tumorBam 
  File tumorBai 
  File? normalBam 
  File? normalBai
  String? normalPanel  # this is listed as a string for a path when it's a file found in the ichor container, but if it's an external file, it needs to be changed to a type File?
  String genomeBuild # hg38 or hg19, only, capitalization matters
  String genomeStyle  #"NCBI" # or NCBI, only
}

## workflow description
workflow ichorCNA {
  input {
    Array[sampleData] batchSamples
    ## Batch level params
    File? exons  
    Int binSizeNumeric ## 10000, but must match the other binSize below
    String binSize  #  "10kb" This must match binSizeNumeric!!!
    Int qual 
    String normal 
    String ploidy 
    String estimateNormal  # these need to be quoted strings in all caps instead of Boolean b/c of R
    String estimatePloidy 
    String estimateClonality 
    String scStates  # states to use for subclonal CN
    Int maxCN 
    Float scPenalty  # penalize subclonal events - n-fold multiplier; n=1 for no penalty,  
    String includeHOMD 
    String plotFileType # "pdf" # "png"
    String plotYlim 
    String likModel  # "t" # if multisample, use "gauss"
    Float minMapScore  # control segmentation - higher (e.g. 0.9999999) leads to higher specificity and fewer segments
    Float maxFracGenomeSubclone 
    Float maxFracCNASubclone 
    Float normal2IgnoreSC # Ignore subclonal analysis when initial normal setting >= this value
    Float txnE # lower (e.g. 0.99) leads to higher sensitivity and more segments
    Float txnStrength  # control segmentation - higher (e.g. 10000000) leads to higher specificity and fewer segments
    # lower (e.g. 100) leads to higher sensitivity and more segments
    Float fracReadsChrYMale 
  }
    ## Workflow and docker level params
    String ichorDocker = "fredhutch/ichorcna:v0.5.0"
    
    Array[String] ucscChrs = ["chr1", "chr2", "chr3", "chr4", "chr5", "chr6", "chr7", 
                           "chr8", "chr9", "chr10", "chr11", "chr12", "chr13", "chr14", 
                           "chr15", "chr16", "chr17", "chr18", "chr19", "chr20", "chr21", 
                           "chr22", "chrX"]

    Array[String] ncbiChrs = ["1", "2", "3", "4", "5", "6", "7", 
                          "8", "9", "10", "11", "12", "13", "14", 
                          "15", "16", "17", "18", "19", "20", "21", 
                          "22", "X"]

  scatter (sample in batchSamples) {
    ## To allow various bams to come from different genomes and styles but be analyzed the same, these reside inside the scatter
    Array[String] chrs = if sample.genomeStyle == "NCBI" then ncbiChrs else ucscChrs
    String? centromere = if sample.genomeBuild == "hg38" then "/ichorCNA/inst/extdata/GRCh38.GCA_000001405.2_centromere_acen.txt" else "/ichorCNA/inst/extdata/GRCh37.p13_centromere_UCSC-gapTable.txt"
    
    call read_counter as read_counter_tumor {
      input:
        bamFile = sample.tumorBam,
        baiFile = sample.tumorBai,
        sampleName = sample.sampleName + "_tumor",
        binSize = binSizeNumeric, 
        qual = qual,
        chrs = chrs,
        taskDocker = ichorDocker
    }

    if (defined(sample.normalBam)) {
    ## This is a little weird, but is changing an optional File input into a File input.  
      File rcNormalBam = select_first([sample.normalBam])
      File rcNnormalBai = select_first([sample.normalBai])
      call read_counter as read_counter_normal {
        input:
          bamFile = rcNormalBam, 
          baiFile = rcNnormalBai,
          sampleName = sample.sampleName + "_normal",
          binSize = binSizeNumeric, 
          qual = qual,
          chrs = chrs,
          taskDocker = ichorDocker
      }
    }
      ## then call ichorCNA using that information
    call run_ichorCNA {
      input:
        tumorWig = read_counter_tumor.readDepth,
        normalWig = read_counter_normal.readDepth,
        normalPanel = sample.normalPanel,
        sampleId = sample.sampleName,
        binSizeName = binSize,
        ichorChrs = chrs,
        sex = sample.sex,
        normal = normal,
        ploidy = ploidy,
        genomeStyle = sample.genomeStyle,
        genomeBuild = sample.genomeBuild,
        estimateNormal = estimateNormal,
        estimatePloidy = estimatePloidy,
        estimateClonality = estimateClonality,
        scStates = scStates,
        maxCN = maxCN,
        centromere = centromere,
        exons = exons,
        includeHOMD = includeHOMD,
        txnE = txnE,
        txnStrength = txnStrength,
        plotFileType = plotFileType,
        plotYlim = plotYlim,
        likModel = likModel,
        minMapScore = minMapScore,
        maxFracGenomeSubclone = maxFracGenomeSubclone,
        maxFracCNASubclone = maxFracCNASubclone,
        normal2IgnoreSC = normal2IgnoreSC,
        scPenalty = scPenalty,
        fracReadsChrYMale = fracReadsChrYMale,
        taskDocker = ichorDocker
    }
  } # End scatter

  output {
    Array[File] tumorWig = read_counter_tumor.readDepth
    Array[File] corrDepth = run_ichorCNA.corrDepth
    Array[File] cna = run_ichorCNA.cna
    Array[File] segTxt = run_ichorCNA.segTxt
    Array[File] seg = run_ichorCNA.seg
    Array[File] rdata = run_ichorCNA.rdata
  }
}


## Task definitions
## Files input should be in form file.bam and file.bam.bai and in the same directory in their original locations so they are localized together by Cromwell too. 
task read_counter {
  input {
    File bamFile
    File baiFile
    String sampleName
    Int binSize
    Int qual
    Array[String] chrs
    String taskDocker
  }
  command {
    set -eo pipefail

    readCounter ~{bamFile} \
      -c ~{sep="," chrs} \
      -w ~{binSize} \
      -q ~{qual} > ~{sampleName}.bin~{binSize}.wig
  }
  runtime {
    memory: "4G"
    cpu: 2
    docker: taskDocker

  }
  output {
    File readDepth = "~{sampleName}.bin~{binSize}.wig"
  }
}

task run_ichorCNA {
  input {
    File tumorWig
    File? normalWig
    String? normalPanel
    String sampleId
    String binSizeName
    Array[String] ichorChrs
    String sex
    String normal
    String ploidy
    String genomeStyle
    String genomeBuild
    String estimateNormal
    String estimatePloidy
    String estimateClonality
    String scStates
    Int maxCN
    String? centromere
    File? exons
    String includeHOMD
    Float txnE
    Float txnStrength
    String plotFileType
    String plotYlim
    String likModel
    Float minMapScore
    Float maxFracGenomeSubclone
    Float maxFracCNASubclone
    Float normal2IgnoreSC
    Float scPenalty
    Float fracReadsChrYMale
    String taskDocker
  }
    Int taskCPU = 2
    ## Notes:  So, anything that R wants to be a number needs to be unquoted.  We cannot use the Boolean type here to my knowledge
    ## for the logical params b/c R gets confused when they aren't all caps TRUE/FALSE that are also unquoted.  
  command {
    set -o pipefail
    read -r -d '' VAR <<'EOF'
    library(ichorCNA); run_ichorCNA(id = '~{sampleId}',
    tumor_wig = '~{tumorWig}',
    repTimeWig = '/ichorCNA/inst/extdata/Koren_repTiming_~{genomeBuild}_~{binSizeName}.wig',
    sex = '~{sex}',
    gcWig = '/ichorCNA/inst/extdata/gc_~{genomeBuild}_~{binSizeName}.wig',
    mapWig = '/ichorCNA/inst/extdata/map_~{genomeBuild}_~{binSizeName}.wig',
    ploidy = '~{ploidy}',
    normal = '~{normal}',
    maxCN = ~{maxCN},
    minMapScore = ~{minMapScore},
    chrs = 'c("~{sep='\", \"' ichorChrs}")',
    includeHOMD = ~{includeHOMD},
    genomeStyle = '~{genomeStyle}',
    genomeBuild = '~{genomeBuild}',
    estimateNormal = ~{estimateNormal},
    estimatePloidy = ~{estimatePloidy},
    estimateScPrevalence = ~{estimateClonality},
    scStates = '~{scStates}',
    likModel = '~{likModel}',
    maxFracGenomeSubclone = ~{maxFracGenomeSubclone},
    maxFracCNASubclone = ~{maxFracCNASubclone},
    normal2IgnoreSC = ~{normal2IgnoreSC},
    scPenalty = ~{scPenalty},
    txnE = ~{txnE},
    txnStrength = ~{txnStrength},
    fracReadsInChrYForMale = ~{fracReadsChrYMale},
    plotFileType = '~{plotFileType}',
    plotYLim = '~{plotYlim}',
    outDir = '.',
    cores  = ~{taskCPU} ~{", centromere = '" + centromere + "'"} ~{", exons.bed = '" + exons + "'"} ~{", normal_wig = '" + normalWig + "'"} ~{", normal_panel = '" + normalPanel + "'"})
    EOF

    echo "$VAR" | Rscript -
  }
  runtime {
    memory: "10G"
    cpu: taskCPU
    docker: taskDocker
  }
  output {
    File corrDepth = "~{sampleId}.correctedDepth.txt"
    File cna = "~{sampleId}.cna.seg"
    File params = "~{sampleId}.params.txt"
    File segTxt = "~{sampleId}.seg.txt"
    File seg = "~{sampleId}.seg"
    File rdata = "~{sampleId}.RData"
  }
}
