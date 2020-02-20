import numpy as np
import pandas as pd

from imgaug import augmenters as iaa
from datetime import datetime
from keras.layers import Input, Dense, Dropout, concatenate, merge
from keras.models import Model, Sequential, model_from_json
from keras.applications import densenet
from keras.preprocessing.image import ImageDataGenerator
from keras.utils import to_categorical
from keras.optimizers import Adam
from sklearn.utils import shuffle
from sklearn.metrics import roc_curve,auc
from cv2 import resize, imwrite, imread
from keras.preprocessing.image import load_img, img_to_array, array_to_img
from keras import backend as k
from imgdemo import ImageGen
from keras.applications import densenet, resnet50, vgg16
from keras.utils import to_categorical, multi_gpu_model
from keras.callbacks import Callback, ModelCheckpoint, TensorBoard
from sklearn.metrics import roc_auc_score
from keras.optimizers import Adam
from sklearn.preprocessing import LabelBinarizer, LabelEncoder as le, OneHotEncoder as ohe
from matplotlib import pyplot as plt
import pickle

k.set_floatx('float32')

trainDf = pd.read_csv('./trainDf_16labels.csv')
devDf = pd.read_csv('./devDf_16labels.csv')
testDf = pd.read_csv('./testDf_16labels.csv')

target_size = (224,224)
image_size = target_size + (3,)
bs = 32

# feature_lst =['No Finding', 'Abnormal','Atelectasis', 'Cardiomegaly', 'Effusion', 'Infiltration', 'Mass',\
#        'Nodule', 'Pneumonia', 'Pneumothorax', 'Consolidation', 'Edema',\
#        'Emphysema', 'Fibrosis', 'Pleural_Thickening', 'Hernia']

feature_lst = ['classification']
demography_lst = ['Patient Age', 'Patient Gender', 'View Position']

x_train = trainDf['path']
y_train = trainDf[feature_lst].values
d_train = pd.get_dummies(trainDf[demography_lst])

x_val = devDf['path']
y_val = devDf['Abnormal'].values
d_val = pd.get_dummies(devDf[demography_lst])

x_test = testDf['path']
y_test = testDf[feature_lst].values
d_test = pd.get_dummies(testDf[demography_lst])

y_train = to_categorical(y_train)
y_val = to_categorical(y_val)
y_test = to_categorical(y_test)

def preprocess_func(img):
    img = img / 255.
    img = resize(img, (224, 224))
      
    imagenet_mean = np.array([0.485, 0.456, 0.406])
    imagenet_std = np.array([0.229, 0.224, 0.225])
    img[:,:,0] -=  imagenet_mean[0]
    img[:,:,1] -=  imagenet_mean[1]
    img[:,:,2] -= imagenet_mean[2]
 
    img[:,:,0] /= imagenet_std[0]
    img[:,:,1] /= imagenet_std[1]
    img[:,:,2] /= imagenet_std[2]
    return img

train_generator = ImageGen(x_train, y_train, 
                           iaa.Sequential(),
                           d_train,
                           target_size=target_size,
                           batch_size=bs,
                           preprocess_fn=preprocess_func)
val_generator = ImageGen(x_val, y_val,
                           iaa.Sequential(),
                           d_val,
                           target_size=target_size,
                           batch_size=bs,
                           shuffle=False,
                           preprocess_fn=preprocess_func)
test_generator = ImageGen(x_test, y_test,
                           iaa.Sequential(),
                           d_test,
                           target_size=target_size,
                           batch_size=bs,
                           shuffle=False,
                           preprocess_fn=preprocess_func)

class RocCallback(Callback): 
    def on_train_begin(self, logs={}):
        self.aucs = []
        self.aucs_test = []

    def on_epoch_end(self, epoch, logs={}):
        current_aucs = []
        current_aucs_test = []
        y_proba = self.model.predict_generator(val_generator)
        y_proba_test = self.model.predict_generator(test_generator)
        
        for i in range(y_proba.shape[-1]):
            score = roc_auc_score(y_val[:, i], y_proba[:, i])
#             print(f"class {i}:{score}")
            current_aucs.append(score)
            
            score_test = roc_auc_score(y_test[:, i], y_proba_test[:, i])
            current_aucs_test.append(score_test)
        
        mean_auc = np.mean(current_aucs)
        self.aucs.append(mean_auc)
        print('Mean Val_AUC: ', self.aucs[-1])
        
        mean_auc_test = np.mean(current_aucs_test)
        self.aucs_test.append(mean_auc_test)
        print('Mean Test_AUC: ', self.aucs_test[-1])

'''
Adding demography features to GAP layer,
Initialized with Keras Chexnet
'''
input_shape = (224,224,3)
input_tensor = Input(shape=input_shape)
dense121 = densenet.DenseNet121(include_top=False,weights=None,input_shape=input_shape, input_tensor=input_tensor,pooling='avg')
x = dense121.output
out1 = Dense(14,activation='sigmoid', name='probas_pred_14')(x)

model = Model(inputs=input_tensor, outputs=out1)
model.load_weights('./brucechou1983_CheXNet_Keras_0.3.0_weights.h5')
sigmoid_14 = model.layers.pop()
model.outputs = [model.layers[-1].output]

input_shape2 = (5,)
input_tensor2 = Input(shape=input_shape2)
dense_demofeatures = Dense(2, activation='relu', name='demography_inp')(input_tensor2)

gap_output = model.get_layer('avg_pool').output
concat_tensor = concatenate([dense_demofeatures, gap_output])
model = Model([input_tensor ,input_tensor2], concat_tensor)
model.layers.append(sigmoid_14)

x = Dense(32, activation='relu', name='Dense1')(model.output)
x = Dense(2,activation='softmax', name='ab_pred')(x)
chex_model_plain = Model([input_tensor ,input_tensor2], x)
chex_model = multi_gpu_model(chex_model_plain)

chex_model.compile(loss='categorical_crossentropy', optimizer=Adam(lr=0.00003), metrics=['accuracy'])

save_best_model = ModelCheckpoint('checkpoints/best_model.{epoch:02d}-{loss:.2f}.hdf5', monitor='val_loss', save_best_only=True, save_weights_only=True)
save_model_every_3_epoch = ModelCheckpoint('checkpoints/model_every_3_epochs.{epoch:02d}-{loss:.2f}.hdf5', save_weights_only=True, period=3)

chex_model.fit_generator(train_generator,epochs=1,validation_data=val_generator,
                                use_multiprocessing=True,
                                max_queue_size=8, 
                                workers=8,
                                callbacks=[RocCallback(), save_best_model,save_model_every_3_epoch])

time_now = datetime.now()
time_str = time_now.date().__str__()+"_"+str(time_now.hour)+"-"+str(time_now.minute)+"-"+str(time_now.second)

chex_model.save('chex_model_{}.h5'.format(time_str))


