# -*- coding: utf-8 -*-
"""groomclassifyIndivAnimal.ipynb

Original file generated by Colab.

#trains and tests a SVC multi-class classifer on a single mouse's behavior
"""

#import most of the packages we'll need
import numpy as np
from sklearn import datasets
from sklearn.metrics import confusion_matrix
from sklearn.model_selection import train_test_split
import pickle
import matplotlib.pyplot as plt
from scipy.stats import zscore


#change the end of the path here in order to access different animals' data
datafile = open(r'/content/gdrive/My Drive/CSStimClassification/4900modelinputs.pkl', 'rb')
data = pickle.load(datafile)
features = data[0]
labels = data[1]

#limit to only grooming times (get rid of all non grooming times)
removeidx = (labels == 0) #non grooming times are labeled as 0
featreduce = features[np.where(removeidx[:,0]==False), :] #in the features matrix, find only the time samples where the label ISN'T 0
featreduce = np.squeeze(featreduce)
labelreduce = labels[np.where(removeidx[:,0]==False), :] #in the labels matrix, find only the time samples where the label ISN'T 0
labelreduce=np.squeeze(labelreduce)

#split our data into "train" and "test" sets for the model
feat_train, feat_test, labels_train, labels_test = train_test_split(featreduce, labelreduce, stratify=labelreduce, test_size = .4, random_state=0)

#nzscore each feature set separately
feat_trainnorm = zscore(feat_train, axis=0)
feat_testnorm = zscore(feat_test, axis=0)

#import the modeling package and run the model on our training dataset
from sklearn.svm import SVC
svm_model_linear = SVC(C = 0.3, max_iter=10000, class_weight='balanced').fit(feat_trainnorm, labels_train)

#once the model is trained, predict the labels on our testing dataset
svm_predictions = svm_model_linear.predict(feat_testnorm)

from sklearn import metrics

# Print the precision and recall, among other metrics
# precision: how many PREDICTED POSITIVES are actually positive?
# recall: how many ACTUAL POSITIVES were predicted to be positive?
print(metrics.classification_report(labels_test, svm_predictions, digits=3))

cm = confusion_matrix(labels_test, svm_predictions, normalize='true')
plt.imshow(cm)
plt.colorbar