# CREATE MODEL SCRIPT----
# Script used for creating the N-gram language models that are used for Word 

# Prediction application ----
# 1. Cleans up text (removes numbers, punctuation and symbols)
# 2. Generates document frequency matrix for unigram, bigram, trigram and 4-gram
#    based on training data
# 3. Computes maximum likelihood estimate for unigram, bigram, trigram and 4-gram
# 4. Prunes bigram, trigam and 4-gram models to include only ngrams that occur more 
#    than once in the text
# 5. Saves the 4-gram, trigram, bigram and unigram models into CSV files that will 
#    be used by the word prediction app
 
# Input Docs: ----
# Training data: sampleData.txt

# Output Docs ----
# 4-gram Model: WordPrediction/FourgramProb.csv
# Trigram Model: WordPrediction/TrigramProb.csv
# Bigram Model: WordPrediction/BigramProb.csv
# Unigram Model: WordPrediction/UnigramProb.csv

# Libraries ----

library(quanteda)
library(dplyr)

# Set seed for reproducibility ----
set.seed(2705)

# Read in sample data ----
conn <- file("sampleData.txt", open = "rb")
sampleSentences <- readLines(conn, skipNul = TRUE)
close(conn)

# Generate Unigram, Bigram and Trigram frequency using quanteda
# Clean up of numbers, punctation and symbols are also done here

# Generate Unigrams and their frequency of occurence in the corpus ----
textDFM <- dfm(sampleSentences,  toLower = TRUE, removeNumbers = TRUE, removePunct = TRUE, 
               removeSeparators = TRUE, removeSymbols = TRUE, removeTwitter = TRUE, 
               removeHyphens = TRUE, what="fasterword")
WordFreq <- data.frame(freq=colSums(textDFM))
WordFreq$Word <- rownames(WordFreq)
rownames(WordFreq) <- NULL
rm(textDFM)

# Generate Bigrams and their frequency of occurence in the corpus ----
textBigram <- dfm(sampleSentences,  toLower = TRUE, removeNumbers = TRUE, removePunct = TRUE, 
                  removeSeparators = TRUE, removeSymbols = TRUE, removeTwitter = TRUE, 
                  removeHyphens = TRUE, what="fasterword", ngrams=2)
BigramFreq <- data.frame(freq=colSums(textBigram))

# Clean up DFM for Bigram ----
rm(textBigram)

#Generate Trigrams and their frequency of occurence in the corpus ----
textTrigram <- dfm(sampleSentences,  toLower = TRUE, removeNumbers = TRUE, removePunct = TRUE, 
                   removeSeparators = TRUE, removeSymbols = TRUE, removeTwitter = TRUE, 
                   removeHyphens = TRUE, what="fasterword", ngrams=3)
TrigramFreq <- data.frame(freq=colSums(textTrigram))
rm(textTrigram)

#Generate 4-grams and their frequency of occurence in the corpus ----
textFourgram <- dfm(sampleSentences,  toLower = TRUE, removeNumbers = TRUE, removePunct = TRUE, 
                   removeSeparators = TRUE, removeSymbols = TRUE, removeTwitter = TRUE, 
                   removeHyphens = TRUE, what="fasterword", ngrams=4)
FourgramFreq <- data.frame(freq=colSums(textFourgram))
rm(textFourgram)

# Divide 4-gram into Trigram and Unigram ----
FourgramFreq$ngram <- rownames(FourgramFreq)
rownames(FourgramFreq) <- NULL
FourgramFreq$ngram <- gsub("_", " ", FourgramFreq$ngram)
FourgramFreq$Prev <- gsub("^((\\w+\\W+){2}\\w+).*$", "\\1", FourgramFreq$ngram)
FourgramFreq$Next <-  gsub("^.* (\\w+|<e>)$", "\\1", FourgramFreq$ngram)
format(object.size(FourgramFreq), units = "Mb")

# Divide Trigram into Bigram and Unigram ----
TrigramFreq$ngram <- rownames(TrigramFreq)
rownames(TrigramFreq) <- NULL
TrigramFreq$ngram <- gsub("_", " ", TrigramFreq$ngram)
TrigramFreq$Prev <- gsub("^((\\w+\\W+){1}\\w+).*$", "\\1", TrigramFreq$ngram)
TrigramFreq$Next <-  gsub("^.* (\\w+|<e>)$", "\\1", TrigramFreq$ngram)
format(object.size(TrigramFreq), units = "Mb")

## Extract Previous and Next words from Bigram ----
BigramFreq$ngram <- rownames(BigramFreq)
rownames(TrigramFreq) <- NULL
BigramFreq$ngram <- gsub("_", " ", BigramFreq$ngram)
BigramFreq$Prev <- gsub("^(\\w+|<s>) .*$", "\\1", BigramFreq$ngram)
BigramFreq$Next <-  gsub("^.* (\\w+|<e>)$", "\\1", BigramFreq$ngram)
format(object.size(BigramFreq), units = "Mb")

# Generate 4-gram probabilities using MLE ----
FourgramProb <- inner_join(FourgramFreq, TrigramFreq, by=c("Prev"="ngram"))
FourgramProb <- FourgramProb[,1:5]
names(FourgramProb) <- c("FourgramFreq", "Fourgram", "Trigram", "Next", "TrigramFreq")
FourgramProb$MLEProb <- FourgramProb$FourgramFreq/FourgramProb$TrigramFreq
format(object.size(FourgramProb), units = "Mb")

# Prune 4-grams to those with more than 1 occurence in the corpus ----
FourgramProb <- filter(FourgramProb, FourgramFreq>1)

# Write 4-gram model to file ----
write.csv(FourgramProb, "WordPrediction/FourgramProb.csv", quote=FALSE)

# Clean Up ----
rm(FourgramFreq, FourgramProb)

# Generate Trigram probabilities using MLE ----
TrigramProb <- inner_join(TrigramFreq, BigramFreq, by=c("Prev"="ngram"))
TrigramProb <- TrigramProb[,1:5]
names(TrigramProb) <- c("TrigramFreq", "Trigram", "Bigram", "Next", "BigramFreq")
TrigramProb$MLEProb <- TrigramProb$TrigramFreq/TrigramProb$BigramFreq
format(object.size(TrigramProb), units = "Mb")

# Prune Trigrams to those with more than 1 occurence in the corpus ----
TrigramProb <- filter(TrigramProb, TrigramFreq>1)

# Write Trigram model to file ----
write.csv(TrigramProb, "WordPrediction/TrigramProb.csv", quote=FALSE)

# Clean Up ----
rm(TrigramFreq, TrigramProb)

## Generate Bigram Probabilities using MLE ----
BigramProb <- inner_join(BigramFreq, WordFreq, by=c("Prev"="Word"))
names(BigramProb) <- c("BigramFreq", "Bigram", "Prev", "Next", "PrevFreq")
BigramProb$MLEProb <- BigramProb$BigramFreq/BigramProb$PrevFreq
format(object.size(BigramProb), units = "Mb")

# Prune Bigrams to those with more than 1 occurence in the corpus ----
BigramProb <- filter(BigramProb, BigramFreq>1)

# Clean Up ----
rm(BigramFreq)

#Generate Unigram probabilities using MLE ----
WordProb <- select(WordFreq, Word, freq) %>% mutate(MLEProb = freq/sum(WordFreq$freq))

# Calculate Kneser-Ney Continuation for Unigram ----

#Using Bigram Probabilities table, find the number of bigrams preceeding each word ----
PrevWordCount <- group_by(BigramProb, Next) %>% summarize(PrevCount=n()) %>% arrange(desc(PrevCount))
UnigramProb <- left_join(WordProb, PrevWordCount, by=c("Word"="Next"))
UnigramProb$KNProb <- UnigramProb$PrevCount/nrow(BigramProb)
names(UnigramProb) <- c( "Next", "freq", "MLEProb", "PrevCount", "KNProb")

#Clean Up ----
rm(WordProb, WordFreq, PrevWordCount)

#Write computed Bigram and Unigram probabilities into files ----
write.csv(UnigramProb, "WordPrediction/UnigramProb.csv", quote=FALSE)
write.csv(BigramProb, "WordPrediction/BigramProb.csv", quote=FALSE)



