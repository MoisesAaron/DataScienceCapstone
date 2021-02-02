### Word Prediction Application

This application was developed for the Capstone Project for the Data Science Specialization in Coursera by Johns Hopkins University

The shiny application is found through this link:
https://ceathiel.shinyapps.io/WordPrediction/

#### How the word prediction is done

The prediction is done using stupid backoff algorithm on Trigram, Bigram and Unigram models. 

When a word is entered in the text field, the application attempts to find suitable match from the Trigram Model using the computed MLE for each Trigram. If no trigram match is found, it backs off to find a match in the Bigram Model, again using MLE.

Finally, if no Trigram or Bigram match is found, it looks at Unigrams and provides a recommendation based on the computed Kneser-Ney probability for the unigram

In the interest of speed, the N-gram models have been pre-processed and resulting computations are saved into CSV files which the application reads in during initialization.

#### Files in the repository:

1. ui.R - user-interface for word prediction application
2. server.R - server logic for this word prediction application. It also contains the `predictNextWord` function that generates the next word predictions.
3. UnigramProb.csv - file containing the Unigram MLE and Kneser-Ney probabilities computed from the training corpus
4. BigramProb.csv - file containing the Bigram MLE probabilities computed from the training corpus
4. TrigramProb.csv - file containing the Trigram MLE probabilities computed from the training corpus
5. FourgramProb.csv - file containing the Trigram MLE probabilities computed from the training corpus
6. include.md - file used to include application details in the Shiny ui
7. tree.jpg - decision tree diagram used for the UI

If you are interested in finding the code that generates the n-gram models, you can refer to https://github.com/Ceathiel/DataScienceCapstone
