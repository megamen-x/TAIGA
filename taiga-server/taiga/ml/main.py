import os
import torch
from tqdm import tqdm
from ml.configs.config import MainConfig
from ml.utils.utils import load_detector, load_classificator, open_mapping, extract_crops
from confz import FileSource 
from PIL import Image, ExifTags
from datetime import datetime, timedelta
import numpy as np
import pandas as pd
from typing  import Union, Dict


class AnimalRegistration:
    """
    Реализация класса регистрации
    Поля:
    1. data_start_registration - дата начала регистрации
    2. images - хранилище фоток определенной регистрации
    2. max_count - максимальное количество обьектов одного класса внутри одной регистрации
    3. species - класс животного конкретной регистрации
    """

    def __init__(
            self,
            data_start_registration: datetime,
            count_animals: int,
            class_animal: str,
            file_path: str
    ) -> None:
        self.data_start_registration = data_start_registration
        self.max_count = count_animals
        self.images = dict()
        self.update(data_start_registration, file_path, count_animals)
        self.species = class_animal

    def get_max_count(self) -> int:
        return self.max_count

    def set_max_count(self, count: int) -> None:
        self.max_count = count

    def get_animal_species(self) -> str:
        return self.species

    def get_data_start(self) -> datetime:
        return self.data_start_registration

    def get_data_end(self) -> datetime:
        return self.data_end_registration

    def update(
            self,
            data_end_registration: datetime,
            file_path: str,
            count_animals: int
    ) -> None:
        self.data_end_registration = data_end_registration
        self.images[file_path] = count_animals
        if count_animals > self.max_count:
            self.max_count = count_animals
        self.set_duration()

    def get_images(self) -> Dict[str, int]:
        return self.images

    def get_duration(self) -> timedelta:
        return self.duration

    def set_duration(self) -> None:
        self.duration = self.data_end_registration - self.data_start_registration


def sorted_files_by_time(files: list) -> tuple:
    list_dates = []
    for file in files:
        img = Image.open(file)
        img_exif = img.getexif()
        if img_exif is None:
            print('Sorry, image has no exif data.')
            return []
        else:
            flag = False
            for key, val in img_exif.items():
                if key in ExifTags.TAGS and ExifTags.TAGS[key] == 'DateTime':
                    flag = True
                    datetime_object = datetime.strptime(val, '%Y:%m:%d %H:%M:%S')
                    list_dates.append(datetime_object)
                    break
            if not flag:
                print('Sorry, image has no datetime metadata')
                return []
    combined = list(zip(files, list_dates))
    # Sort the combined list based on the datetime
    sorted_combined = sorted(combined, key=lambda x: x[1])
    listfiles = [item[0] for item in sorted_combined]
    list_dates = [item[1] for item in sorted_combined]
    return listfiles, list_dates

# Настройка конфига
main_config = MainConfig(config_sources=FileSource(file="ml/configs/config.yml"))
device = 'cuda' if torch.cuda.is_available() else 'cpu'
mapping = open_mapping(path_mapping=main_config.mapping)
detector_config = main_config.detector
classificator_config = main_config.classificator
detector = load_detector(detector_config).to(device)
classificator = load_classificator(classificator_config).to(device)


# Обработка изображений
def process_images(list_files) -> Union[pd.DataFrame, None]:
    list_files, list_dates = sorted_files_by_time(list_files)
    if len(list_files):
        regs = {
                'Badger': [],
                'Bear': [],
                'Bison': [],
                'Cat': [],
                'Dog': [],
                'Empty': [],
                'Fox': [],
                'Goral': [],
                'Hare': [], 
                'Lynx': [], 
                'Marten': [], 
                'Moose': [], 
                'Mountain_Goat': [], 
                'Musk_Deer': [], 
                'Racoon_Dog': [], 
                'Red_Deer': [], 
                'Roe_Deer': [], 
                'Snow_Leopard': [], 
                'Squirrel': [], 
                'Tiger': [],
                'Wolf': [],
                'Wolverine': []
            }

        num_packages_det = np.ceil(len(list_files) / detector_config.batch_size).astype(np.int32)
        with torch.no_grad():
            for i in tqdm(range(num_packages_det), colour="red"):
                # Inference detector
                batch_images_det = list_files[detector_config.batch_size * i:
                                            detector_config.batch_size * (1 + i)]
                results_det = detector(
                    batch_images_det,
                    iou=detector_config.iou,
                    conf=detector_config.conf,
                    imgsz=detector_config.imgsz,
                    verbose=False,
                    device=device
                )

                if len(results_det) > 0:
                    # Extract crop by bboxes
                    dict_crops = extract_crops(results_det, config=classificator_config)

                    # Inference classificator
                    for img_name, batch_images_cls in dict_crops.items():
                        num_packages_cls = np.ceil(len(batch_images_cls) / classificator_config.batch_size).astype(
                            np.int32)
                        for j in range(num_packages_cls):
                            batch_images_cls = batch_images_cls[classificator_config.batch_size * j:
                                                                classificator_config.batch_size * (1 + j)]
                            logits = classificator(batch_images_cls.to(device))
                            probabilities = torch.nn.functional.softmax(logits, dim=1)
                            top_p, top_class_idx = probabilities.topk(1, dim=1)

                            # Locate torch Tensors to cpu and convert to numpy
                            top_p = top_p.cpu().numpy().ravel()
                            top_class_idx = top_class_idx.cpu().numpy().ravel()

                            class_names = [mapping[top_class_idx[idx]] for idx, _ in enumerate(batch_images_cls)]
                            unique_species = list(set(class_names))
                            for el in unique_species:
                                if el == 'empty':
                                    continue
                                if len(regs[el]) == 0:
                                    regs[el].append(AnimalRegistration(data_start_registration=list_dates[i],
                                                                    count_animals=class_names.count(el), class_animal=el,
                                                                    file_path=list_files[i]))
                                else:
                                    if list_dates[i] - regs[el][-1].get_data_end() > timedelta(minutes=30):
                                        regs[el].append(AnimalRegistration(data_start_registration=list_dates[i],
                                                                        count_animals=class_names.count(el),
                                                                        class_animal=el, file_path=list_files[i]))
                                    else:
                                        regs[el][-1].update(list_dates[i], list_files[i], class_names.count(el))
        final_dict = {
            'name_folder': [],
            'class': [],
            'date_registration_start': [],
            'flag': [], 'count': [], 'max_count': [], 'link': []
        }
        df = pd.DataFrame(final_dict)
        for key, val in regs.items():
            for el in val:
                for img_path, count_img in el.get_images().items():
                    new_row = {'name_folder': 1, 'class': el.get_animal_species(),
                            'date_registration_start': el.get_data_start().strftime('%Y-%m-%d %H:%M:%S'),
                            'flag': el.get_duration(),
                            'count': count_img,
                            'max_count': el.get_max_count(),
                            'link': img_path}
                    df.loc[len(df)] = new_row
        df = df.sort_values(by=['date_registration_start'])
        df.to_csv('answer.csv', index=False)
        return df
    else:
        return None


if __name__ == '__main__':
    list_files = os.listdir('train_data_Minprirodi\\traps\\1\\images')
    list_files = [os.path.join('train_data_Minprirodi\\traps\\1\\images', el) for el in list_files]
    answer = process_images(list_files)
    print(answer)