## Do as I say, not as I do: A lexical distributional account of English locative verb class acquisition
- Twomey, Chang & Ambridge 
- website: http://sites.google.com/site/sentenceproductionmodel/Home/locativemodel
- June 2014

- the model requires perl and LENS
- LENS is available here http://tedlab.mit.edu/~dr/Lens/
- a mac version is available here: http://hbrouwer.github.com/lensosx/

### To train models
- The input environments that are used to train the model come from the envtransgen, envnopostverbtheme and envnodetomit files
- Test set is generated by envgramtest 
- runall.perl generates training and test sets, then runs the models specified in cmdfile.
- To create models, use command:
```
$ runall.perl & 
```

### Command file
- There is a command file (cmdfile) has one line for each type of model that you want to run.  It will train 30 of each (incrementing -s X each time).  
- “SET -s 0 envtransgen & & -m 50 | rmtransmes2.perl” creates the “transitive generalisation” model using 
- a grammar with mass noun determiner omission
- “SET -s 0 envnopostverbtheme & & -m 50 | rmtransmes2.perl” creates the “no post verbal theme role” model 
- using a grammar with mass noun determiner omission, no simple transitives, and no prepositional datives 
- “SET -s 0 envnodetomit & & -m 50 | rmtransmes2.perl” creates the “no article omission” model using a grammar 
- with no mass noun determiner omission 
- “SET -s 0 envtransgen &set directWordHidden 1& -m 50 | rmtransmes2.perl” creates the “no ccompress” model 
- using the transitive generalisation grammar (envtransgen) and removing the ccompress layer from the model 
- architecture (using the &set directWordHidden 1& parameter)

- results are saved into the working directory as the model runs and are automatically archived once finished by runall.perl (using arcthis.perl). If you stop the model running before it has finished, run arcthis.perl from the command line to clean up the folder.

### Figures
- to produce stats and figures run modelstat.Rmd in the model working directory from the command line as follows:
```
# for the transitive Generalisation model
gr sim*transgenm50
# for No compress model
gr sim*Word*
# for Determiner omission model
gr sim*omit*
# for No post verbal themes
gr sim*post* 
```

### File details
- cmdfile - specifies model grammars and parameters
- model.tcl - passes model parameters to runall.perl
- runall.perl - runs the files below
- dualpath.in - lens files that creates model
- arcthis.perl - archives model files in the working directory
- decode9.perl - creates readable output file from results 
- syncode.perl - tags output for category and syntax, scores output correct/incorrect
- generate2.perl - generates message-sentence pairs from grammars
- gr - runs R script for computing statistics and produces html summary.  This requires the knitr package in R.
- translate.perl - translates output of generate2.perl into lens-readable format
- rmtransmes2.perl - removes messages from class B, C and D transitives
