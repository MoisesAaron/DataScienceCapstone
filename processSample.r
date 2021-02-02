# Raw script used for experimentng with different language models

# Libraries ----
library(quanteda)
library(dplyr)

# Set seed for reproducibility. ----
set.seed(2705)

# Set sample size to be used from whole corpus ----
samplesize <- .05

# Set percent of sample to be taken for testing ----
testsize <- .25

# Read twitter sample ----
twitter <- readLines("final/en_US/en_US.twitter.txt", skipNul = TRUE)
sample <- as.logical(rbinom (n=length(twitter),size=1, prob = samplesize))
sampleTweets <- twitter[sample]

# Set aside text for testing ----
test <- as.logical(rbinom (n=length(sampleTweets),size=1, prob = testsize))
testTweets <- sampleTweets[test]

# Set aside text for training model ----
modelTweets <- sampleTweets[!test]
rm(twitter)

# Read blogs sample ----
blogs <- readLines("final/en_US/en_US.blogs.txt")
sample <- as.logical(rbinom (n=length(blogs),size=1, prob = samplesize))
sampleBlogs <- blogs[sample]

# Set aside text for testing ----
test <- as.logical(rbinom (n=length(sampleBlogs),size=1, prob = testsize))
testBlogs <- sampleBlogs[test]

# Set aside text for training model ----
modelBlogs <- sampleBlogs[!test]
rm(blogs)

# Read news sample ----
conn <- file("final/en_US/en_US.news.txt", open = "rb")
news <- readLines(conn, skipNul = TRUE)
sample <- as.logical(rbinom (n=length(news),size=1, prob = samplesize))
close(conn)
sampleNews <- news[sample]

# Set aside text for testing ----
test <- as.logical(rbinom (n=length(sampleNews),size=1, prob = testsize))
testNews <- sampleNews[test]

# Set aside text for training model ----
modelNews <- sampleNews[!test]
rm(news, conn)

# Join all model and test text to separate vectors and clean up objects ----
modelText <- c(modelTweets, modelBlogs, modelNews)
rm(modelTweets, modelBlogs, modelNews)
testText <- c(testTweets, testBlogs, testNews)

# Write test text to file for later use ----
write.table(testText, "testdata.txt", col.names = FALSE, row.names = FALSE, quote=FALSE)
rm(testTweets, testBlogs, testNews, testText)
rm(test, sample)
rm(sampleTweets, sampleBlogs, sampleNews)

# Remove non-ASCII characters ----
modelText <- iconv(modelText, "latin1", "ASCII", sub="")

# Tokenize to sentences ----
sampleSentences <- tokenize(modelText, what="sentence", simplify = TRUE)

rm(modelText)

# Generate Unigram, Bigram and Trigram frequency using quanteda ----
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

# Generate Trigrams and their frequency of occurence in the corpus ----
textTrigram <- dfm(sampleSentences,  toLower = TRUE, removeNumbers = TRUE, removePunct = TRUE, 
                   removeSeparators = TRUE, removeSymbols = TRUE, removeTwitter = TRUE, 
                   removeHyphens = TRUE, what="fasterword", ngrams=3)
TrigramFreq <- data.frame(freq=colSums(textTrigram))
rm(textTrigram)

# Divide Trigram into Bigram and Unigram ----
TrigramFreq$ngram <- rownames(TrigramFreq)
rownames(TrigramFreq) <- NULL
TrigramFreq$ngram <- gsub("_", " ", TrigramFreq$ngram)
TrigramFreq$Prev <- gsub("^((\\w+\\W+){1}\\w+).*$", "\\1", TrigramFreq$ngram)
TrigramFreq$Next <-  gsub("^.* (\\w+|<e>)$", "\\1", TrigramFreq$ngram)
format(object.size(TrigramFreq), units = "Mb")

# Extract Previous and Next words from Bigram ----
BigramFreq$ngram <- rownames(BigramFreq)
rownames(TrigramFreq) <- NULL
BigramFreq$ngram <- gsub("_", " ", BigramFreq$ngram)
BigramFreq$Prev <- gsub("^(\\w+|<s>) .*$", "\\1", BigramFreq$ngram)
BigramFreq$Next <-  gsub("^.* (\\w+|<e>)$", "\\1", BigramFreq$ngram)
format(object.size(BigramFreq), units = "Mb")

# Calculate Kneser-Ney Discount where N1 and N2 are Trigrams with count of 1 and 2 ----
trigramTotal <- nrow(TrigramFreq)
n1 <- nrow(TrigramFreq[TrigramFreq$freq==1,])
n2 <- nrow(TrigramFreq[TrigramFreq$freq==2,])
D = n1 / (n1 + 2*n2)

# Generate Trigram probabilities using MLE with and without Kneser-Ney Discount ----
TrigramProb <- inner_join(TrigramFreq, BigramFreq, by=c("Prev"="ngram"))
TrigramProb <- TrigramProb[,1:5]
names(TrigramProb) <- c("TrigramFreq", "Trigram", "Bigram", "Next", "BigramFreq")
TrigramProb$MLEProb <- TrigramProb$TrigramFreq/TrigramProb$BigramFreq
TrigramProb$MLEProbDiscount <- (TrigramProb$TrigramFreq-D)/TrigramProb$BigramFreq
format(object.size(TrigramProb), units = "Mb")

# Calculate Kneser-Ney Discount where N1 and N2 are Bigrams grams with count of 1 and 2 ----
bigramTotal <- nrow(BigramFreq)
n1Bigram <- nrow(BigramFreq[BigramFreq$freq==1,])
n2Bigram <- nrow(BigramFreq[BigramFreq$freq==2,])
DBigram = n1Bigram / (n1Bigram + 2*n2Bigram)

# Generate Bigram Probabilities using MLE ----
BigramProb <- inner_join(BigramFreq, WordFreq, by=c("Prev"="Word"))
names(BigramProb) <- c("BigramFreq", "Bigram", "Prev", "Next", "PrevFreq")
BigramProb$MLEProb <- BigramProb$BigramFreq/BigramProb$PrevFreq
BigramProb$MLEProbDiscount <- (BigramProb$BigramFreq-DBigram)/BigramProb$PrevFreq
format(object.size(BigramProb), units = "Mb")

TrigramProb$Continuation <- paste0(gsub("^.* (\\w+)$", "\\1", TrigramProb$Bigram), " ", TrigramProb$Next)

# Clean Up ----
rm(BigramFreq, TrigramFreq)

# Limit Bigrams to those with more than 1 occurence in the corpus ----
BigramProb <- filter(BigramProb, BigramFreq>1)

#Generate Unigram probabilities (MLE and Kneser Ney Continuation) ----
WordProb <- select(WordFreq, Word, freq) %>% mutate(MLEProb = freq/sum(WordFreq$freq))

# Using Bigram Probabilities table, find the number of bigrams preceeding each word ----
PrevWordCount <- group_by(BigramProb, Next) %>% summarize(PrevCount=n()) %>% arrange(desc(PrevCount))
UnigramProb <- left_join(WordProb, PrevWordCount, by=c("Word"="Next"))
UnigramProb$KNProb <- UnigramProb$PrevCount/nrow(BigramProb)
names(UnigramProb) <- c( "Next", "freq", "MLEProb", "PrevCount", "KNProb")

# Clean Up ----
rm(WordProb, WordFreq)

# Write computed Ngram probabilities into files ----
write.csv(UnigramProb, "WordPrediction/UnigramProb.csv", quote=FALSE)
write.csv(BigramProb, "WordPrediction/BigramProb.csv", quote=FALSE)
write.csv(TrigramProb, "WordPrediction/TrigramProb.csv", quote=FALSE)

# Generate test data ----
choices <- list(c("eat", "give", "sleep", "die")
                , c("spiritual", "financial","marital", "horticultural")
                , c("decade", "weekend", "morning", "month")
                , c("happiness", "hunger", "sleepiness", "stress")
                , c("look", "picture", "minute", "work")
                , c("account", "incident", "case", "matter")
                , c("hand", "arm", "toe", "finger")
                , c("side", "top", "middle", "center")
                , c("inside", "outside", "weekly", "daily")
                , c("novels", "pictures", "stories", "movies"))

sentences <- c("When you breathe, I want to be the air for you. I'll be there for you, I'd live and I'd"
               ,"Guy at my table's wife got up to go to the bathroom and I asked about dessert and he started telling me about his"
               ,"I'd give anything to see arctic monkeys this"
               ,"Talking to your mom has the same effect as a hug and helps reduce your"
               ,"When you were in Holland you were like 1 inch away from me but you hadn't time to take a"
               ,"I'd just like all of these questions answered, a presentation of evidence, and a jury to settle the"
               ,"I can't deal with unsymetrical things. I can't even hold an uneven number of bags of groceries in each"
               ,"Every inch of you is perfect from the bottom to the"
               ,"I’m thankful my childhood was filled with imagination and bruises from playing"
               ,"I like how the same people are in almost all of Adam Sandler's")
