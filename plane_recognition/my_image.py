import numpy as np
import os
from PIL import Image
import my_image

#Метод конвертации изображения в массив размерности (1,20,20,3):


def convert_image(img):
    img = Image.open('{}'.format(img))
    arr = np.asarray(img, dtype='uint8')
    arr = np.array([arr])

    return arr


#Метод изменения размера изображения по высоте и ширине(в нашем случае сжатие до 400x400 пикселей):


def resize_image(input_image_path, size, output_image_path=False):
    original_image = Image.open(input_image_path)
    #width, height = original_image.size

    resized_image = original_image.resize(size)
    #width, height = resized_image.size

    if output_image_path == True:
        resized_image.save(output_image_path)

    return resized_image


#Метод перебирающий основное изображение по квадратам 20x20(такой формат необходим нейросети для распознавания образов)
# с шагом в 4 пикселя по высоте и ширине. В итоге изначальный снимок 400x400 разбивается на
# 26*26 сегментов, каждый из которых прогоняется через нейросеть и при первом нахождении объекта, возвращает строку,
# уведомляющую об этом.


def search_image(path):
    image = resize_image(path, size=(100, 100))
    y1, y2 = 0, 20
    image_pyxels = []

    for i in range(26):
        x1, x2 = 0, 20

        for j in range(26):
            cropped = image.crop((x1, y1, x2, y2))
            arr = np.asarray(cropped, dtype='uint8')
            image_pyxels.append(arr)
            x1 += 4
            x2 += 4
        y1 += 4
        y2 += 4

    return np.array(image_pyxels)


#Нормализуем значение пикселей и создаем из них списки


def image_processing(pyxels_list):
    pyxels_result = []

    for i in range(400):
        pyxels_result.append([
            float(pyxels_list[i]) / 255,
            float(pyxels_list[i + 400]) / 255,
            float(pyxels_list[i + 800]) / 255
        ])

    return pyxels_result