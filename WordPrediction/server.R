#
# This is the server logic of a Word Prediction Application
#

#Initialize libraries
library(shiny)
library(quanteda)
library(data.table)
library(dplyr)

#Read in ngram models
UnigramProb <- fread("UnigramProb.csv", header = T, sep = ",")
BigramProb <- fread("BigramProb.csv", header = T, sep = ",")
TrigramProb <- fread("TrigramProb.csv", header = T, sep = ",")
FourgramProb <- fread("FourgramProb.csv", header = T, sep = ",")

#Create function for predicting next words using ngram model
predictNextWord <- function(sentence, choices=NULL) {
    
    #Clean up input sentence similar to how training set was cleaned up
    #Remove numbers, punctuation, symbols
    sentenceToken <- tokenize(tolower(sentence), removeNumbers = TRUE, removePunct = TRUE, 
                              removeSeparators = TRUE, removeSymbols = TRUE, removeTwitter = TRUE, 
                              removeHyphens = TRUE, what="fasterword", simplify = TRUE)
    
    #Check if entered text is valid and display a message
    if (length(sentenceToken) == 0) {
        return("App is ready. Please enter a phrase with valid characters from the alphabet in the textbox.")
    } else {
        #Start Predicting Next Word
        
        #Initialize empty data frame to hold the next word predictions
        match <- data.frame(Next=character(), MLEProb=numeric())
        
        #Attempt to match to a 4-gram if sentence has 3 or more words using MLE 
        if (length(sentenceToken) >= 3) {
            lastTrigram <- paste0(sentenceToken[length(sentenceToken)-2], " ",
                                  sentenceToken[length(sentenceToken)-1], " ", 
                                  sentenceToken[length(sentenceToken)])
            match <- filter(FourgramProb, lastTrigram==Trigram) %>% 
                arrange(desc(MLEProb))  %>% 
                top_n(5, MLEProb) %>% select(Next, MLEProb)
        }
        
        #If sentence has only 2 words or if match has less than 5 results
        if (length(sentenceToken) >= 2 | nrow(match) < 5) {
            lastBigram <- paste0(sentenceToken[length(sentenceToken)-1], " ", sentenceToken[length(sentenceToken)])
            x <- filter(TrigramProb, lastBigram==Bigram) %>% top_n(5, MLEProb) %>% 
                select(Next, MLEProb) %>% mutate(MLEProb=MLEProb*0.4) 
            match <- filter(x, !(Next %in% match$Next)) %>% bind_rows(match)
        }
        
        #If sentence has only 1 word or if match has less than 5 results
        if (length(sentenceToken) == 1 | nrow(match) < 5){
            lastWord <- sentenceToken[length(sentenceToken)]
            x <- filter(BigramProb, lastWord==Prev) %>%  top_n(5, MLEProb) %>%
                select(Next, MLEProb) %>% mutate(MLEProb=MLEProb*0.4*0.4)
            match <- filter(x, !(Next %in% match$Next)) %>% bind_rows(match)
        } 
        
        #If Bigram match has failed, if match has less than 5 results
        if (nrow(match) < 5){
            x <- top_n(UnigramProb, 5, KNProb) %>% select(Next, KNProb) %>% 
                mutate(MLEProb=KNProb*0.4*0.4*0.4)
            match <- filter(x, !(Next %in% match$Next)) %>% bind_rows(match)
        } 
        
        #Sort matches by MLE
        match <- arrange(match, desc(MLEProb))
        
        return(paste0(sentence, " ", match$Next))
    }
}

#Update the UI with the output of next word prediction
shinyServer(function(input, output) {
    output$predictedsentence <- renderText({ 
        text <- predictNextWord(input$words) 
        paste(text, collapse = "\n")
        })
    
    output$wordcloud <- renderPlot({
        par(mfrow=c(1,3))
        wordcloud(top3$Trigram, top3$TrigramFreq, scale=c(3,.3), colors=(brewer.pal(8, 'Dark2')))
        wordcloud(top2$Bigram, top2$BigramFreq, scale=c(3,.3), colors=(brewer.pal(8, 'Dark2')))   
    })
})
