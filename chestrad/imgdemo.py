import numpy as np
from keras.utils import Sequence
from keras.preprocessing.image import load_img, img_to_array, array_to_img
from skimage.transform import resize
import os



class ImageGen(Sequence):
    
    def __init__(self, imgs, y, aug, demo=None, target_size=(224, 224), save_format='png',
                 batch_size=32, shuffle=True,preprocess_fn=None, seed=None,
                 dtype='float16', save_prefix='', save_to_dir=False):
        
        self.imgs = np.array(imgs)
        self.y = np.array(y)
        self.aug = aug
        self.demo = demo
        self.batch_size = batch_size
        self.target_size = target_size
        self.image_shape = target_size + (3,)
        self.shuffle = shuffle
        self.preprocess_fn = preprocess_fn
        self.seed = seed
        self.dtype = dtype
        self.total_batches_seen = 0
        self.save_to_dir = save_to_dir
        self.save_prefix = save_prefix
        self.save_format = save_format
        self.on_epoch_end()
    
    def __len__(self):
        return int(np.ceil(len(self.imgs) / float(self.batch_size)))
    
    def on_epoch_begin(self, _):
        assert demo.shape[-1] != 5, " 'demo' variable should age, gender, view_position"
        
    def on_epoch_end(self):
        self.total_batches_seen += 1
        self.indexes = np.arange(len(self.imgs))
        if self.shuffle:
            if self.seed is not None:
                np.random.seed(self.seed + self.total_batches_seen)
            np.random.shuffle(self.indexes)
    


    def __getitem__(self, batch_index):
        index_array = self.indexes[batch_index*self.batch_size:(batch_index + 1)*self.batch_size]
        batch_x = np.zeros(
            (len(index_array),) + self.image_shape,
            dtype=self.dtype)
        # build batch of image data
        for i, index in enumerate(index_array):
            img_path = self.imgs[index]
            img = load_img(img_path, target_size=self.target_size)
            img = img_to_array(img.convert('RGB'))
            batch_x[i] = self.preprocess_fn(img)

        batch_x = self.aug.augment_images(batch_x)

        if self.save_to_dir:
            img_paths = self.imgs[index_array]
            for i in range(len(batch_x)):
                img = array_to_img(batch_x[i],scale=True)
                fname = '{prefix}_{index}_{filename}.{format}'.format(prefix=self.save_prefix,
                                                                    index=batch_index + i,
                                                                    filename=os.path.basename(img_paths[i]),
                                                                    format=self.save_format)
                img.save(os.path.join(self.save_to_dir, fname))

        # build batch of labels
        batch_y = self.y[index_array]
        batch_d = self.demo.iloc[index_array]
        return [batch_x, batch_d], batch_y
    
    