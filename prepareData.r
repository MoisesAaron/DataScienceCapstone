# PREPARE DATA SCRIPT ----
# Script used for preparing text sample for creating n-gram models 

# 1. Reads in sample text based on a sample size and partitions it into training
#    and test set
# 2. Removes non-ASCII characters from text
# 3. Tokenizes sample text into sentences and filters out sentences with profanity

# Input Docs: ----
# Twitter text: final/en_US/en_US.twitter.txt
# Blog text: final/en_US/en_US.blogs.txt
# News text: final/en_US/en_US.news.txt
# Profanity filter: swearWords.txt

# Output Docs ----
# Training data: sampleData.txt
# Test data: testdata.txt

# Libraries

library(quanteda)
library(dplyr)

# Set seed for reproducibility. ----
set.seed(2705)

# Set sample size to be used from whole corpus ----
samplesize <- .20

# Set percent of sample to be taken for testing ----
testsize <- .25

# Read twitter sample ----
twitter <- readLines("final/en_US/en_US.twitter.txt", skipNul = TRUE)
sample <- as.logical(rbinom (n=length(twitter),size=1, prob = samplesize))
sampleTweets <- twitter[sample]

#Set aside text for testing ----
test <- as.logical(rbinom (n=length(sampleTweets),size=1, prob = testsize))
testTweets <- sampleTweets[test]

#Set aside text for training model ----
modelTweets <- sampleTweets[!test]
rm(twitter)

# Read blogs sample ----
blogs <- readLines("final/en_US/en_US.blogs.txt")
sample <- as.logical(rbinom (n=length(blogs),size=1, prob = samplesize))
sampleBlogs <- blogs[sample]

#Set aside text for testing ----
test <- as.logical(rbinom (n=length(sampleBlogs),size=1, prob = testsize))
testBlogs <- sampleBlogs[test]

#Set aside text for training model ----
modelBlogs <- sampleBlogs[!test]
rm(blogs)

# Read news sample ----
conn <- file("final/en_US/en_US.news.txt", open = "rb")
news <- readLines(conn, skipNul = TRUE)
sample <- as.logical(rbinom (n=length(news),size=1, prob = samplesize))
close(conn)
sampleNews <- news[sample]

#Set aside text for testing ----
test <- as.logical(rbinom (n=length(sampleNews),size=1, prob = testsize))
testNews <- sampleNews[test]

#Set aside text for training model ----
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

# Read in words for profanity filter ----
conn <- file("swearWords.txt", open = "rb")
profanityFilter <- readLines(conn, skipNul = TRUE)
close(conn)

# Filter out sentences with profanity ----
profane <- rowSums(sapply(profanityFilter, function(x) grepl(sprintf('\\b%s\\b', x), sampleSentences)))
sampleSentences <- sampleSentences[profane==0]
rm(profane, profanityFilter)

# Write dataset to file for later use ----
write.table(sampleSentences, "sampleData.txt", col.names = FALSE, row.names = FALSE, quote=FALSE)
